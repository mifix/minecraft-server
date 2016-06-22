FROM java:8-jre-alpine

ENV MC_PATH /home/minecraft/server

RUN set -x && adduser -D minecraft

RUN set -x && apk add --no-cache wget bash

USER minecraft

RUN set -x && mkdir -p $MC_PATH


WORKDIR $MC_PATH

RUN set -x && ln -s ../minecraft_server.jar


EXPOSE 25565

VOLUME $MC_PATH

COPY docker-entrypoint.sh $MC_PATH/../

ENTRYPOINT ["../docker-entrypoint.sh"]

CMD ["java", "-jar", "minecraft_server.jar", "nogui"]

ENV JVM_OPTS -Xmx1024M -Xms1024M

# Download Minecraft Server
ARG MC_VERSION
ENV MC_VERSION ${MC_VERSION:-1.10}

RUN set -x && cd /home/minecraft && \
  wget -q -O minecraft_server.jar "https://s3.amazonaws.com/Minecraft.Download/versions/${MC_VERSION}/minecraft_server.${MC_VERSION}.jar"
