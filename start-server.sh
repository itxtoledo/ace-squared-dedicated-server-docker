#!/bin/bash
set -euo pipefail

echo "Running with UID: $(id -u), GID: $(id -g)"

export HOME="${HOME:-/home/steam}"
mkdir -p "$HOME/.steam/sdk64"

# Check if steamcmd is already installed in the persistent directory
cd /opt/steamcmd
if [ ! -f "./steamcmd.sh" ]; then
    echo ">>> SteamCMD not found. Installing to /opt/steamcmd..."
    wget -q https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
    tar -xzf steamcmd_linux.tar.gz
    rm steamcmd_linux.tar.gz
    # Only attempt to change permissions if files exist
    if [ -d "linux32" ]; then
        chmod -R a+rwX linux32/ 2>/dev/null || true
    fi
    if [ -d "linux64" ]; then
        chmod -R a+rwX linux64/ 2>/dev/null || true
    fi
    chmod a+rx ./steamcmd.sh 2>/dev/null || true
    echo ">>> SteamCMD installed successfully!"
else
    echo ">>> SteamCMD already installed, skipping installation"
fi

echo ">>> Executing steamcmd commands"
echo ">>> SteamCMD command: bash ./steamcmd.sh +force_install_dir /opt/server/acesquared +login anonymous +app_update 3252540 validate +quit"
timeout 300 bash ./steamcmd.sh +force_install_dir /opt/server/acesquared +login anonymous +app_update 3252540 validate +quit || {
    echo ">>> SteamCMD execution failed or timed out. This is common on ARM64 systems due to emulation."
    echo ">>> The game server files may need to be pre-downloaded on an x86_64 system or ensure Docker QEMU is properly configured."
    echo ">>> Skipping SteamCMD update and attempting to start server directly if files already exist..."
    if [ -f "/opt/server/acesquared/AceSquaredDedicated.x86_64" ]; then
        echo ">>> Game server files detected, proceeding to start server..."
    else
        echo ">>> Error: Game server files not found at /opt/server/acesquared/AceSquaredDedicated.x86_64"
        echo ">>> Please ensure the game is properly downloaded first."
        exit 1
    fi
}

# Optional: useful for troubleshooting
ldd /opt/server/acesquared/AceSquaredDedicated.x86_64 || true

# Copy steamclient.so for Unity to find via the Steam SDK path
STEAM_SDK_DIR="$HOME/.steam/sdk64"
PLUGIN_SRC="/opt/server/acesquared/AceSquaredDedicated_Data/Plugins/steamclient.so"
PLUGIN_DST="$STEAM_SDK_DIR/steamclient.so"

echo ">>> Copying plugin from $PLUGIN_SRC to $PLUGIN_DST"
cp -f "$PLUGIN_SRC" "$PLUGIN_DST"

echo ">>> Starting server as uid $(id -u) gid $(id -g) HOME=$HOME"
exec "/opt/server/acesquared/AceSquaredDedicated.x86_64"