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
RUN mkdir -p "$HOME" /opt/steamcmd \
 && chmod 0777 "$HOME" /opt/steamcmd

# Diretório de trabalho
WORKDIR /opt/steamcmd

# Script de inicialização que instala steamcmd no primeiro uso
COPY --chmod=0755 ./start-server.sh /usr/local/bin/start-server.sh

CMD ["start-server.sh"]