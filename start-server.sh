#!/bin/bash

cd /opt/server

echo "running steamcmd commands"
./steamcmd.sh +force_install_dir /opt/server/acesquared +login anonymous +app_update 3252540 validate +quit

ldd /opt/server/acesquared/AceSquaredDedicated.x86_64

# ! important step, otherwise your server wont start

# 2) Copy steamclient.so into Steam’s SDK folder so Unity can load it
STEAM_SDK_DIR="${HOME:-/root}/.steam/sdk64"
echo ">>> Ensuring Steam SDK dir exists at $STEAM_SDK_DIR"
echo "copying steamclient.so"
mkdir -p "$STEAM_SDK_DIR"

PLUGIN_SRC="/opt/server/acesquared/AceSquaredDedicated_Data/Plugins/steamclient.so"
PLUGIN_DST="$STEAM_SDK_DIR/steamclient.so"
echo ">>> Copying plugin from $PLUGIN_SRC to $PLUGIN_DST"
cp "$PLUGIN_SRC" "$PLUGIN_DST"

echo ">>> starting server"
"/opt/server/acesquared/AceSquaredDedicated.x86_64"
