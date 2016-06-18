FROM alpine:3.4

ENV MC_PATH /home/minecraft/server
ENV MC_MAP /home/minecraft/map

ENV LIBRARY_PATH=/lib:/usr/lib

RUN set -x && echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

RUN set -x && apk --update add --no-cache \
    python wget tar ca-certificates py-pillow py-numpy@testing py-numpy-dev@testing && \
  apk add --no-cache --virtual=build-dependencies  \
   build-base python-dev py-pip jpeg-dev zlib-dev libx11-dev \
   gcc musl-dev python-dev && \
  ln -s /usr/include/locale.h /usr/include/xlocale.h


RUN set -x && mkdir -p /opt/overviewer && \
  adduser -D minecraft

WORKDIR /opt/overviewer


RUN set -x && \
  wget -q https://raw.githubusercontent.com/python-pillow/Pillow/master/libImaging/Imaging.h && \
  wget -q https://raw.githubusercontent.com/python-pillow/Pillow/master/libImaging/ImPlatform.h && \
  wget -q -O /tmp/ov.tar.gz https://github.com/overviewer/Minecraft-Overviewer/tarball/master && \
  tar xzf /tmp/ov.tar.gz -C /opt/overviewer --strip-components=1 && \
  rm -f /tmp/ov.tar.gz


RUN set -x && \
  python setup.py build && \
  apk del build-dependencies && \
  rm -rf /var/cache/apk/*


USER minecraft

ARG MC_VERSION
ENV MC_VERSION ${MC_VERSION:-1.10}

RUN set -x && cd /home/minecraft && \
  mkdir -p /home/minecraft/.minecraft/versions/${MC_VERSION}/ && \
  wget -q https://s3.amazonaws.com/Minecraft.Download/versions/${MC_VERSION}/${MC_VERSION}.jar -P ~/.minecraft/versions/${MC_VERSION}/ && \
  mkdir -p $MC_MAP

COPY ./config.py /home/minecraft/


ENTRYPOINT ["./overviewer.py", "--config=/home/minecraft/config.py"]
