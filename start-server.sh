#!/bin/bash
set -euo pipefail

echo "My identity: (UID: $(id -u), GID: $(id -g), USER: $(whoami))"

cd /opt/server

export HOME="${HOME:-/home/steam}"
mkdir -p "$HOME/.steam/sdk64"

echo "running steamcmd commands"
bash ./steamcmd.sh +force_install_dir /opt/server/acesquared +login anonymous +app_update 3252540 validate +quit

# Optional: useful for troubleshooting
ldd /opt/server/acesquared/AceSquaredDedicated.x86_64 || true

# Copy steamclient.so for Unity to find via the Steam SDK path
STEAM_SDK_DIR="$HOME/.steam/sdk64"
PLUGIN_SRC="/opt/server/acesquared/AceSquaredDedicated_Data/Plugins/steamclient.so"
PLUGIN_DST="$STEAM_SDK_DIR/steamclient.so"

echo ">>> Copying plugin from $PLUGIN_SRC to $PLUGIN_DST"
cp -f "$PLUGIN_SRC" "$PLUGIN_DST"

echo ">>> starting server as uid $(id -u) gid $(id -g) HOME=$HOME"
exec "/opt/server/acesquared/AceSquaredDedicated.x86_64"