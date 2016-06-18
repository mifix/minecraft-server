FROM alpine:3.4

ENV MC_PATH /data


RUN set -x && mkdir -p /opt/mc_cmd


COPY mc_cmd.sh /opt/mc_cmd/mc_cmd.sh

VOLUME $MC_PATH


ENTRYPOINT ["/opt/mc_cmd/mc_cmd.sh"]
