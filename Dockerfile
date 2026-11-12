FROM alpine:3.22

RUN apk add --no-cache \
        bash ca-certificates gcompat libstdc++ libcrypto3 libssl3 \
        openssl openssh supervisor && \
    apk add --no-cache --virtual .download-deps wget && \
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
        -O /usr/bin/cloudflared && \
    chmod 0755 /usr/bin/cloudflared && \
    apk del .download-deps

COPY entrypoint.sh /entrypoint.sh
COPY run-websocket.sh /usr/local/bin/run-websocket.sh
COPY run-cloudflared.sh /usr/local/bin/run-cloudflared.sh
COPY persist-ssh-host-keys.sh /usr/local/bin/persist-ssh-host-keys.sh
COPY supervisord.conf /etc/supervisord.conf
RUN chmod 0755 /entrypoint.sh /usr/local/bin/run-websocket.sh \
        /usr/local/bin/run-cloudflared.sh /usr/local/bin/persist-ssh-host-keys.sh && \
    mkdir -p /config /program /run/sshd

EXPOSE 22
VOLUME ["/config", "/program"]
ENTRYPOINT ["/entrypoint.sh"]
