FROM alpine:3.4

ENV MC_PATH /home/minecraft/server

RUN set -x && apk add --no-cache \
    openssh-client bash \
    fuse libacl libattr lz4 openssl pkgconfig python3 \
 && apk add --no-cache --virtual=build-dependencies \
    acl-dev attr-dev fuse-dev gcc lz4-dev musl-dev openssl-dev python3-dev \
 && python3 -m ensurepip \
 && pip3 install -U pip virtualenv \
 && virtualenv /env \
 && /env/bin/pip3 --no-cache-dir install setuptools_scm llfuse \
 && /env/bin/pip3 --no-cache-dir install borgbackup \
 && apk del build-dependencies


RUN set -x && adduser -D minecraft


USER minecraft

RUN set -x && mkdir -p $MC_PATH


WORKDIR $MC_PATH


COPY backup.sh $MC_PATH/../

ENTRYPOINT ["../backup.sh"]
