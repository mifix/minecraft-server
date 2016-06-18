#!/bin/bash

set -euo pipefail

cd $MC_PATH


say() {
  echo "/say ${@}" > $MC_PATH/mc_server
}

cmd() {
  echo "/${@}" > $MC_PATH/mc_server
}

finish() {
  cmd "save-on"
}
trap finish EXIT


backup() {
  $borg create -v --stats --show-rc -C lz4  \
    --remote-path $rpath \
    $REPOSITORY::$ARCHIVE $MC_PATH \
    --exclude $BORG_CACHE_DIR --exclude-caches > /tmp/borg-output 2>&1
}


borg="/env/bin/borg"
rpath="/usr/local/bin/borg1/borg1"



if [[ $# -gt 0 && ${1:-} == "backup" ]]; then

  if [[ -z ${BORG_PASSPHRASE:-} ]]; then
    echo "BORG_PASSPHRASE environment variable not set"
    exit 1
  fi

  export BORG_CACHE_DIR=$MC_PATH/.borg_cache


  ARCHIVE="$MC_NAME-$(date +%Y-%m-%d-%H:%M)"

  if [[ ! -d $BORG_CACHE_DIR ]]; then
    $borg init $REPOSITORY
  fi


  say "[BACKUP] Saving chunks..."
  cmd "save-off"
  cmd "save-all flush"


  say "[BACKUP] Uploading..."
  backup
  while read -r line; do
    say ${line}
  done < <(egrep "Duration|archive|terminating" /tmp/borg-output)

  cmd "save-on"
  say "[BACKUP] Finished."

fi

if [[ $# -gt 0 && ${1:-} == "purge" ]]; then
  borg prune --stats -v --remote-path $rpath $REPOSITORY --prefix ${MC_NAME}- \
      --keep-daily=7 --keep-weekly=4 --keep-monthly=2
fi


exec "$@"


