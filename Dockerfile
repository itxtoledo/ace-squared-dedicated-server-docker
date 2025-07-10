FROM debian:bookworm-slim

LABEL maintainer="Akseli Vanhamaa"

RUN apt-get update && apt-get install -y \
    lib32gcc-s1 \
    ca-certificates \
    wget

RUN mkdir /opt/server
WORKDIR /opt/server

RUN wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
RUN tar -xvzf steamcmd_linux.tar.gz && rm steamcmd_linux.tar.gz

COPY ./start-server.sh .

CMD ["./start-server.sh"]
