#!/bin/bash
set -euo pipefail

echo "My identity: (UID: $(id -u), GID: $(id -g), USER: $(whoami))"

export HOME="${HOME:-/home/steam}"
mkdir -p "$HOME/.steam/sdk64"

# Verifica se steamcmd já está instalado no diretório persistente
cd /opt/steamcmd
if [ ! -f "./steamcmd.sh" ]; then
    echo ">>> SteamCMD não encontrado. Instalando em /opt/steamcmd..."
    wget -q https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
    tar -xzf steamcmd_linux.tar.gz
    rm steamcmd_linux.tar.gz
    chmod -R a+rwX /opt/steamcmd
    chmod a+rx /opt/steamcmd/steamcmd.sh
    echo ">>> SteamCMD instalado com sucesso!"
else
    echo ">>> SteamCMD já instalado, pulando instalação"
fi

echo ">>> Executando comandos do steamcmd"
bash ./steamcmd.sh +force_install_dir /opt/server/acesquared +login anonymous +app_update 3252540 validate +quit

# Optional: useful for troubleshooting
ldd /opt/server/acesquared/AceSquaredDedicated.x86_64 || true

# Copy steamclient.so for Unity to find via the Steam SDK path
STEAM_SDK_DIR="$HOME/.steam/sdk64"
PLUGIN_SRC="/opt/server/acesquared/AceSquaredDedicated_Data/Plugins/steamclient.so"
PLUGIN_DST="$STEAM_SDK_DIR/steamclient.so"

echo ">>> Copiando plugin de $PLUGIN_SRC para $PLUGIN_DST"
cp -f "$PLUGIN_SRC" "$PLUGIN_DST"

echo ">>> Iniciando servidor como uid $(id -u) gid $(id -g) HOME=$HOME"
exec "/opt/server/acesquared/AceSquaredDedicated.x86_64"