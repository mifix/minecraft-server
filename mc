#!/bin/bash
# vi: set ft=sh fdm=marker fdl=0 fen :

set -euo pipefail

# mc start $name
# mc stop $name
#
# mc cmd $name "time set day"
#
# mc generate_map $name

IMAGE_PREFIX="wthkiste"
VOLUME_PREFIX="mc_store_"
CNT_PREFIX="minecraft_"


# shellcheck disable=SC2086
SCRIPTPATH=$( cd "$(dirname $0)" ; pwd -P )



############################# Library ########################################## {{{

debug() {
  echo -e "\033[90m[DEBUG] ${*}\033[0m"
}

print() {
  echo -e "\033[1;36m$*\033[0m"
}

error() {
  echo -e "\033[91m${*}\033[0m"
  exit 1
}

docker_exec() {
  local cmd="docker"
  debug $cmd "$@"
  $cmd "$@"
}

############################## Volumes #######################################

Volume() {
  _volume_name="${VOLUME_PREFIX}$1"
  _volume_exists=$( docker_exec volume ls | grep -c "$_volume_name" || true)
}

Volume_create() {
  if [ "$_volume_exists" == 1 ]; then
    debug "Volume $_volume_name already exists"
  else
    print " * Creating volume $_volume_name"

    docker_exec volume create --name="${_volume_name}"
  fi
}

Volume_name() {
  echo "$_volume_name"
}

Volume_remove() {
  print " * Removing volume $_volume_name"
  docker_exec volume rm "$_volume_name"
}



############################## Images ########################################

Image() {
  _image_name="${IMAGE_PREFIX}/$1:${2:-latest}"
  _image_exists=$( docker_exec images --format "{{.Repository}}:{{.Tag}}" | grep -c "$_image_name" || true )
}

Image_pull() {
  if [ "$_image_exists" == 1 ]; then
    debug "Image $_image_name already exists"
  else
    print " * Pulling image $_image_name"
    docker_exec pull "$_image_name"
  fi
}

Image_name() {
  echo "$_image_name"
}

Image_remove() {
  print " * Removing image $_image_name"
  docker_exec rmi "$_image_name"
}



############################## Container ######################################

# Container initializer
# $1 ... container name
# $2 ... image name
# $3 ... array of port mappings (eg. "8080:80")
# $4 ... array of volume mappings (eg. "foo_volume:/data")
Container() {
  _cnt_name="$CNT_PREFIX$1"
  _cnt_ports=()
  _cnt_volumes=()

  _cnt_exists=$( docker_exec ps -a --format "{{.Names}}" | grep -c "$_cnt_name" || true )
  _cnt_running=$( docker_exec ps --format "{{.Names}}" | grep -c "$_cnt_name" || true )

  if [ $# -gt 1 ]; then
    _cnt_image="$2"
  fi

  if [ $# -gt 2 ]; then
    _cnt_ports=($3)
  fi

  if [ $# -gt 3 ]; then
    _cnt_volumes=($4)
  fi
}


Container_ports() {
  local ports=""
  for port in "${_cnt_ports[@]}"; do
    ports="${ports} -p $port"
  done

  echo "$ports"
}


Container_volumes() {
  local volumes=""
  for port in "${_cnt_volumes[@]}"; do
    volumes="${volumes} -v $port"
  done

  echo "$volumes"
}


# shellcheck disable=SC2120
Container_run() {
  local cmd=${1:-}

  if [ "$_cnt_exists" == 1 ]; then
    debug "Container $_cnt_name already exists. Starting it."
    Container_start
  else
    print " * Starting container $_cnt_name for the first time"

    # (we actually want to split ports and volume args)
    # shellcheck disable=SC2046 disable=2086
    docker_exec run -d --name "$_cnt_name" $(Container_ports) $(Container_volumes) "$_cnt_image" $cmd
  fi
}


# shellcheck disable=SC2120
Container_start() {
  local cmd=${1:-}

  if [ "$_cnt_running" == 1 ]; then
    debug "Container $_cnt_name already running"
  else
    print " * Starting container $_cnt_name"

    docker_exec start "$_cnt_name"
  fi
}

Container_stop() {
  print " * Stopping container $_cnt_name"
  docker_exec stop "$_cnt_name"
}

Container_remove() {
  print " * Removing container $_cnt_name"
  docker_exec rm "$_cnt_name"
}

Container_log() {
  docker_exec logs -f "$_cnt_name"
}

################################################################################### }}}

start() {
  if [ $# -ne 1 ]; then
    	echo -e "\nUsage:\n$0 start [world_name] \n"
      error "World name is missing."
  fi

  local WORLD_NAME="$1"


  Volume "$WORLD_NAME"
  Volume_create


  Image "minecraft" "${MC_VERSION:-latest}"
  Image_pull

  declare -a mc_ports=("${MC_PORT:-25565}:25565")
  declare -a mc_volumes=("$(Volume_name):/home/minecraft/server")


  Container "$WORLD_NAME" "$(Image_name)" "${mc_ports[*]}" "${mc_volumes[*]}"
  Container_run
}


stop() {
  if [ $# -ne 1 ]; then
      echo -e "\nUsage:\n$0 stop [world_name] \n"
      error "World name is missing."
  fi

  local WORLD_NAME="$1"

  Container "$WORLD_NAME"
  Container_stop
}

log() {
  if [ $# -ne 1 ]; then
      echo -e "\nUsage:\n$0 log [world_name] \n"
      error "World name is missing."
  fi

  local WORLD_NAME="$1"

  Container "$WORLD_NAME"
  Container_log
}




usage() {
  echo -e "\nUsage:\n$0 [start|stop|cmd|generate_map] [world_name] \n"
  error "Wrong arguments."
}

main() {
  if [ $# -lt 2 ]; then usage; fi

  local command="$1"
  local WORLD_NAME="$2"

  local config_file="${SCRIPTPATH}/${WORLD_NAME}.cfg"

  if [ ! -e $config_file ]; then
    error "Config file $config_file is missing."
  else
    source $config_file
  fi


  case $command in
    "start" )
      start "$WORLD_NAME"
      ;;
    "stop" )
      stop "$WORLD_NAME"
      ;;
    "log" )
      log "$WORLD_NAME"
      ;;
    * )
      usage
      ;;
  esac

}

main $*
