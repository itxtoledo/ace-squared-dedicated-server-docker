#!/bin/bash
set -euo pipefail

# Verify that the mounted volume is writable
if [ ! -w "/opt/steamcmd" ]; then
    echo "Error: The directory /opt/steamcmd (your local 'files' directory) is not writable by the container." >&2
    exit 1
fi

# Verify that the game server mounted volume is writable
if [ ! -w "/opt/server/acesquared" ]; then
    echo "Error: The directory /opt/server/acesquared (your local 'br-obex-1' directory) is not writable by the container." >&2
    exit 1
fi

export HOME="${HOME:-/home/steam}"
mkdir -p "$HOME/.steam/sdk64"

STEAMCMD_MOUNTED="/opt/steamcmd"
STEAMCMD_EXECUTABLE="$STEAMCMD_MOUNTED/steamcmd.sh"

# Check if steamcmd.sh exists in the mounted volume. If not, download it.
if [ ! -f "$STEAMCMD_EXECUTABLE" ]; then
    echo ">>> Downloading SteamCMD..."
    
    # Create the directory if it doesn't exist
    mkdir -p "$STEAMCMD_MOUNTED"
    
    # Download, extract, and set permissions for SteamCMD
    wget -q https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz -P "$STEAMCMD_MOUNTED"
    tar -xzf "$STEAMCMD_MOUNTED/steamcmd_linux.tar.gz" -C "$STEAMCMD_MOUNTED"
    rm "$STEAMCMD_MOUNTED/steamcmd_linux.tar.gz"
    
    chmod +x "$STEAMCMD_EXECUTABLE"
    
    # Also grant execute permission for the 32-bit compatibility layer if it exists
    if [ -f "$STEAMCMD_MOUNTED/linux32/steamcmd" ]; then
        chmod +x "$STEAMCMD_MOUNTED/linux32/steamcmd"
    fi
fi

if timeout 300 bash $STEAMCMD_EXECUTABLE +force_install_dir /opt/server/acesquared +login anonymous +app_update 3252540 validate +quit; then
    echo ">>> Server updated successfully"
else
    echo ">>> Server update failed"
    # Verificar se os arquivos do servidor existem mesmo após falha na atualização
    if [ -f "/opt/server/acesquared/AceSquaredDedicated.x86_64" ]; then
        echo ">>> Starting server with existing files"
    else
        echo ">>> Server files not found, update required"
        exit 1
    fi
fi

# Optional: useful for troubleshooting
if [ -f "/opt/server/acesquared/AceSquaredDedicated.x86_64" ]; then
    ldd /opt/server/acesquared/AceSquaredDedicated.x86_64 || true
fi

# Copy steamclient.so for Unity to find via the Steam SDK path
STEAM_SDK_DIR="$HOME/.steam/sdk64"
PLUGIN_DST="$STEAM_SDK_DIR/steamclient.so"

# Find the actual steamclient.so file
FOUND_PLUGIN_SRC=$(find /opt/server/acesquared -name "steamclient.so" -type f -print -quit)

if [ -n "$FOUND_PLUGIN_SRC" ]; then # Check if FOUND_PLUGIN_SRC is not empty
    if [ -d "$STEAM_SDK_DIR" ]; then
        cp -f "$FOUND_PLUGIN_SRC" "$PLUGIN_DST"
    fi
else
    echo ">>> Warning: steamclient.so not found"
fi

exec "/opt/server/acesquared/AceSquaredDedicated.x86_64"