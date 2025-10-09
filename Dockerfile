FROM debian:bookworm-slim

LABEL maintainer="Akseli Vanhamaa"

RUN apt-get update && apt-get install -y \
    bash \
    ca-certificates \
    wget \
    lib32gcc-s1 \
    lib32stdc++6 \
    libc6-i386 \
 && rm -rf /var/lib/apt/lists/*

# Writable HOME and server dir for arbitrary UIDs
ENV HOME=/home/steam
RUN mkdir -p "$HOME" /opt/server \
 && chmod 0777 "$HOME" /opt/server

WORKDIR /opt/server

RUN wget -q https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
 && tar -xzf steamcmd_linux.tar.gz \
 && rm steamcmd_linux.tar.gz \
 # Important: keep write perms so steamcmd can self-update
 && chmod -R a+rwX /opt/server \
 && chmod a+rx /opt/server/steamcmd.sh

COPY --chmod=0755 ./start-server.sh /usr/local/bin/start-server.sh

CMD ["start-server.sh"]