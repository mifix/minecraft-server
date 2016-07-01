#!/bin/bash
# vi: set ft=sh fdm=marker fdl=0 fen :

set -euo pipefail

IMAGE_PREFIX="wthkiste"
IMAGE_NAME="minecraft-server"
VOLUME_PREFIX="mc_store_"
CNT_PREFIX="minecraft_"


# shellcheck disable=SC2086
SCRIPTPATH=$( cd "$(dirname $0)" ; pwd -P )



############################# Library ########################################## {{{

_Reset="\033[0m"
_DarkGray="\033[90m"
_BoldCyan="\033[1;36m"
_LightRed="\033[91m"
_BoldWhite="\033[1;37m"
_BoldRed="\033[1;31m"
_BoldGreen="\033[1;32m"
_BoldYellow="\033[1;33m"
_FancyX='\xE2\x9C\x97'
_FancyE='\x21'
_Checkmark='\xE2\x9C\x93'

debug() {
  echo -e "$_DarkGray[DEBUG] ${*}$_Reset"
}

print() {
  echo -e "$_BoldCyan$*$_Reset"
}

error() {
  echo -e "$_LightRed${*}$_Reset"
  exit 1
}

you_got_it_dude() {
  echo -e "  $_BoldGreen$_Checkmark$_Reset  $_BoldWhite$*$_Reset"
}

that_sucks() {
  echo -e "  $_BoldRed$_FancyX$_Reset  $_BoldWhite$*$_Reset"
}

hodor() {
  echo -e "  $_BoldYellow$_FancyE$_Reset  $_BoldWhite$*$_Reset"
}

docker_exec() {
  local cmd="docker"
  debug $cmd "$@"
  $cmd "$@"
}

############################## Volumes #######################################

Volume() {
  _volume_name="${VOLUME_PREFIX}$1"
  _volume_exists=$( docker_exec volume ls | grep -c "${_volume_name}\$" || true)
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

Volume_exists() {
  echo $_volume_exists
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

Image_exists() {
  echo $_image_exists
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
  _cnt_envs=()

  _cnt_exists=$( docker_exec ps -a --format "{{.Names}}" | grep -c "${_cnt_name}\$" || true )
  _cnt_running=$( docker_exec ps --format "{{.Names}}" | grep -c "${_cnt_name}\$" || true )

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

Container_exists() {
  echo $_cnt_exists
}

Container_name() {
  echo $_cnt_name
}

Container_running() {
  echo $_cnt_running
}


Container_ports() {
  # Set ports
  if [ $# -eq 1 ]; then
    _cnt_ports=($1)
  else
    local ports=""
    if [ "${#_cnt_ports[@]}" -gt 0 ]; then
      for port in "${_cnt_ports[@]}"; do
        ports="${ports} -p $port"
      done
    fi

    echo "$ports"
  fi
}


Container_volumes() {
  # Set volumes
  if [ $# -eq 1 ]; then
    _cnt_volumes=($1)
  else
    local volumes=""
    if [ "${#_cnt_volumes[@]}" -gt 0 ]; then
      for volume in "${_cnt_volumes[@]}"; do
        volumes="${volumes} -v $volume"
      done
    fi

    echo "$volumes"
  fi
}

Container_environment() {
  # Set env vars
  if [ $# -eq 1 ]; then
    _cnt_envs=($1)
  else
    local envs=""
    if [ "${#_cnt_envs[@]}" -gt 0 ]; then
      for e in "${_cnt_envs[@]}"; do
        envs="${envs} -e $e"
      done
    fi

    echo "$envs"
  fi
}


# shellcheck disable=SC2120
Container_run() {
  local cmd=${1:-}

  if [ "$_cnt_exists" == 1 ]; then
    debug "Container $_cnt_name already exists. Starting it."
    Container_start
  else
    if [ ! "$cmd" ]; then
      print " * Starting container $_cnt_name for the first time"
      # (we actually want to split ports and volume args)
      # shellcheck disable=SC2046 disable=2086
      docker_exec run -d --name "$_cnt_name" $(Container_ports) $(Container_volumes) $(Container_environment) "$_cnt_image"
    else
      print " * Running command '$cmd' in container $_cnt_name"
      # (we actually want to split ports and volume args)
      # shellcheck disable=SC2046 disable=2086
      docker_exec run --rm -it --name "$_cnt_name" $(Container_ports) $(Container_volumes) $(Container_environment) "$_cnt_image" $cmd
    fi
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




start() { # {{{
  if [ $# -ne 1 ]; then
    	echo -e "\nUsage:\n$0 start [world_name] \n"
      error "World name is missing."
  fi

  local WORLD_NAME="$1"


  Volume "$WORLD_NAME"
  Volume_create


  Image $IMAGE_NAME "${MC_VERSION:-latest}"
  Image_pull

  declare -a mc_ports=("${MC_PORT:-25565}:25565")
  declare -a mc_volumes=("$(Volume_name):/home/minecraft/server")


  Container "$WORLD_NAME" "$(Image_name)" "${mc_ports[*]}" "${mc_volumes[*]}"
  Container_run
} # }}}

stop() { # {{{
  if [ $# -ne 1 ]; then
      echo -e "\nUsage:\n$0 stop [world_name] \n"
      error "World name is missing."
  fi

  local WORLD_NAME="$1"

  Container "$WORLD_NAME"
  Container_stop
} # }}}

status() {  # {{{
  if [ $# -ne 1 ]; then
    echo -e "\nUsage:\n$0 status [world_name] \n"
    error "World name is missing."
  fi

  local WORLD_NAME="$1"

  Volume "$WORLD_NAME"
  Image $IMAGE_NAME "${MC_VERSION:-latest}"
  Container "$WORLD_NAME" "$(Image_name)"

  echo
  print " Server status for world '${WORLD_NAME}':"

  if [ $(Image_exists) == 1 ]; then
    you_got_it_dude "Image '$(Image_name)' exists"
  else
    that_sucks "Image '$(Image_name)' does not exists locally"
  fi

  if [ $(Volume_exists) == 1 ]; then
    you_got_it_dude "Volume '$(Volume_name)' exists"
  else
    that_sucks "Volume '$(Volume_name)' is missing"
  fi

  if [ $(Container_exists) == 1 ]; then
    if [ $(Container_running) == 1 ]; then
      you_got_it_dude "Container '$(Container_name)' exists and is running"
    else
      hodor "Container '$(Container_name)' exists but is NOT running"
    fi
  else
    that_sucks "Container '$(Container_name)' does not exist"
  fi

  echo
  print " Command runner for world '${WORLD_NAME}':"
  Image "minecraft-cmd" "latest"
  Container "${WORLD_NAME}_cmd" "$(Image_name)"

  if [ $(Image_exists) == 1 ]; then
    you_got_it_dude "Image '$(Image_name)' exists"
  else
    that_sucks "Image '$(Image_name)' does not exists locally"
  fi

  if [ $(Container_exists) == 1 ]; then
    if [ $(Container_running) == 1 ]; then
      you_got_it_dude "Container '$(Container_name)' exists and is running"
    else
      hodor "Container '$(Container_name)' exists but is NOT running"
    fi
  else
    that_sucks "Container '$(Container_name)' does not exist"
  fi


  echo
  print " Map generator for world '${WORLD_NAME}':"
  Volume "${WORLD_NAME}_map"
  Image "minecraft-map" "latest"
  Container "${WORLD_NAME}_map" "$(Image_name)"

  if [ $(Image_exists) == 1 ]; then
    you_got_it_dude "Image '$(Image_name)' exists"
  else
    that_sucks "Image '$(Image_name)' does not exists locally"
  fi

  if [ $(Volume_exists) == 1 ]; then
    you_got_it_dude "Volume '$(Volume_name)' exists"
  else
    that_sucks "Volume '$(Volume_name)' is missing"
  fi

  if [ $(Container_exists) == 1 ]; then
    if [ $(Container_running) == 1 ]; then
      you_got_it_dude "Container '$(Container_name)' exists and is running"
    else
      hodor "Container '$(Container_name)' exists but is NOT running"
    fi
  else
    that_sucks "Container '$(Container_name)' does not exist"
  fi



  echo
  print " Backup for world '${WORLD_NAME}':"
  Image "minecraft-backup" "latest"
  Container "${WORLD_NAME}_backup" "$(Image_name)"

  if [ $(Image_exists) == 1 ]; then
    you_got_it_dude "Image '$(Image_name)' exists"
  else
    that_sucks "Image '$(Image_name)' does not exists locally"
  fi

  if [ $(Container_exists) == 1 ]; then
    if [ $(Container_running) == 1 ]; then
      you_got_it_dude "Container '$(Container_name)' exists and is running"
    else
      hodor "Container '$(Container_name)' exists but is NOT running"
    fi
  else
    that_sucks "Container '$(Container_name)' does not exist"
  fi


  echo -e "\n"
} # }}}

upgrade() { # {{{
  if [ $# -ne 1 ]; then
    echo -e "\nUsage:\n$0 log [world_name] \n"
    error "World name is missing."
  fi

  local WORLD_NAME="$1"

  stop "$WORLD_NAME"

  Container "$WORLD_NAME"
  Container_remove

  start "$WORLD_NAME"
} # }}}

destroy() { # {{{
  if [ $# -ne 1 ]; then
    echo -e "\nUsage:\n$0 log [world_name] \n"
    error "World name is missing."
  fi

  local WORLD_NAME="$1"

  stop "$WORLD_NAME"

  Container "$WORLD_NAME"
  Container_remove

  Container "${WORLD_NAME}_cmd"
  Container_remove

  Container "${WORLD_NAME}_map"
  Container_remove

  Volume "$WORLD_NAME"
  Volume_remove

  Volume "${WORLD_NAME}_map"
  Volume_remove
} # }}}

log() { # {{{
  if [ $# -ne 1 ]; then
      echo -e "\nUsage:\n$0 log [world_name] \n"
      error "World name is missing."
  fi

  local WORLD_NAME="$1"

  Container "$WORLD_NAME"
  Container_log
} # }}}

cmd() { # {{{
  if [ $# -ne 2 ]; then
    echo -e "\nUsage:\n$0 cmd [world_name] [command] \n"
    error "World name or command is missing."
  fi

  local WORLD_NAME="$1"
  local command="$2"

  Volume "$WORLD_NAME"
  Volume_create


  Image "minecraft-cmd" "latest"
  Image_pull

  declare -a mc_volumes=("$(Volume_name):/data")

  Container "${WORLD_NAME}_cmd" "$(Image_name)"
  Container_volumes "${mc_volumes[*]}"
  Container_run "$command"
} # }}}

backup() { # {{{
  if [ $# -ne 2 ]; then
    echo -e "\nUsage:\n$0 cmd [world_name]\n"
    error "World name is missing."
  fi

  local WORLD_NAME="$1"
  local command="$2"

  Volume "$WORLD_NAME"
  Volume_create


  Image "minecraft-backup" "latest"
  Image_pull

  declare -a mc_volumes=("
    $(Volume_name):/home/minecraft/server"
    "$HOME/.ssh/backup:/home/minecraft/.ssh/id_rsa:ro" 
    "$HOME/.ssh/known_hosts:/home/minecraft/.ssh/known_hosts:ro"
  )

  declare -a mc_environment=(
    "BORG_PASSPHRASE=${BORG_PASSPHRASE}"
    "MC_NAME=${WORLD_NAME}"
    "REPOSITORY=${REPOSITORY}"
  )

  Container "${WORLD_NAME}_backup" "$(Image_name)"
  Container_volumes "${mc_volumes[*]}"
  Container_environment "${mc_environment[*]}"
  Container_run "$command"
} # }}}

generate_map() {  # {{{
  if [ $# -ne 1 ]; then
    echo -e "\nUsage:\n$0 generate_map [world_name] \n"
    error "World name is missing."
  fi

  local WORLD_NAME="$1"
  local command=""

  Volume "$WORLD_NAME"
  Volume_create
  local world_volume=$(Volume_name)

  Volume "${WORLD_NAME}_map"
  Volume_create
  local map_volume=$(Volume_name)


  Image "minecraft-map" "latest"
  Image_pull

  declare -a mc_volumes=(
    "$world_volume:/home/minecraft/server"
    "$map_volume:/home/minecraft/map"
  )

  Container "${WORLD_NAME}_map" "$(Image_name)"
  Container_volumes "${mc_volumes[*]}"
  Container_run "$command"
} # }}}



#### MAIN {{{

usage() {
  echo -e "\nUsage:\n$0 [start|stop|status|upgrade|cmd|generate_map] [world_name] \n"
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
    "status" )
      status "$WORLD_NAME"
      ;;
    "upgrade" )
      upgrade "$WORLD_NAME"
      ;;
    "cmd" )
      shift 2
      cmd "$WORLD_NAME" "$*"
      ;;
    "generate_map" )
      generate_map "$WORLD_NAME"
      ;;
    "backup" )
      backup "$WORLD_NAME" backup
      ;;
    "backup_purge" )
      backup "$WORLD_NAME" purge
      ;;
    "_destroy" )
      destroy "$WORLD_NAME"
      ;;
    * )
      usage
      ;;
  esac

} # }}}

main $*
