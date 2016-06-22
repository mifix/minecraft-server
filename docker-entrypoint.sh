#!/bin/bash

set -euo pipefail

pipe="$MC_PATH/mc_server"

cd $MC_PATH

if [[ $# -gt 0 && $1 == "java" ]]; then

  echo "eula=true" > eula.txt

  if [ ! -e $pipe ]; then
    mkfifo $pipe
  fi

  exec java $JVM_OPTS -jar minecraft_server.jar nogui <> $pipe

fi


exec "$@"
