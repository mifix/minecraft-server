FROM java:8

ENV MC_PATH /home/minecraft/server

# Add minecraft user
RUN set -x && useradd minecraft -m -s /bin/bash


# RUN set -x && apt-get -q update && \
#   DEBIAN_FRONTEND=noninteractive apt-get -q -y --no-install-recommends install \
#   wget && \
#   apt-get clean && rm -rf /var/lib/apt/lists/*


USER minecraft

RUN set -x && mkdir -p $MC_PATH


WORKDIR $MC_PATH

RUN set -x && ln -s ../minecraft_server.jar


EXPOSE 25565

VOLUME $MC_PATH

COPY docker-entrypoint.sh $MC_PATH/../

ENTRYPOINT ["../docker-entrypoint.sh"]

CMD ["java", "-Xmx1024M", "-Xms1024M", "-jar", "minecraft_server.jar", "nogui"]


# Download Minecraft Server
ARG MC_VERSION
ENV MC_VERSION ${MC_VERSION:-1.10}

RUN set -x && cd /home/minecraft && \
  wget -q -O minecraft_server.jar "https://s3.amazonaws.com/Minecraft.Download/versions/${MC_VERSION}/minecraft_server.${MC_VERSION}.jar"
