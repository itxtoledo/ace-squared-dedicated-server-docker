#!/bin/bash
set -euo pipefail

echo "Running with UID: $(id -u), GID: $(id -g)"

export HOME="${HOME:-/home/steam}"
mkdir -p "$HOME/.steam/sdk64"

# STEAMCMD_BASE is the internal location of SteamCMD in the Docker image
STEAMCMD_BASE="/opt/steamcmd"

# When the volume is mounted, it may override the built-in SteamCMD
# So we check for a backup method first
STEAMCMD_EXECUTABLE=""

# Check if steamcmd exists in the mounted volume
if [ -f "/opt/steamcmd/steamcmd.sh" ]; then
    # If volume is mounted with existing SteamCMD files, use those
    echo ">>> SteamCMD found in mounted volume, using that version"
    STEAMCMD_EXECUTABLE="/opt/steamcmd/steamcmd.sh"
else
    # If volume is empty (no SteamCMD files), try to find the built-in one in the image
    # Since the volume mount overrides the image contents, we need to ensure SteamCMD exists
    # If it doesn't exist in the mounted volume, we need to copy it from a backup location
    # The Dockerfile should have installed SteamCMD at /opt/steamcmd during build
    # But if the volume is mounted empty, we have to make sure it exists
    if [ -f "$STEAMCMD_BASE/steamcmd.sh" ]; then
        echo ">>> SteamCMD not found in mounted volume, but found in internal location"
        # Copy to mounted volume to ensure persistence
        cp -f $STEAMCMD_BASE/steamcmd.sh /opt/steamcmd/ 2>/dev/null || true
        cp -f $STEAMCMD_BASE/linux32/* /opt/steamcmd/linux32/ 2>/dev/null || true
        STEAMCMD_EXECUTABLE="/opt/steamcmd/steamcmd.sh"
    else
        echo ">>> No SteamCMD found in image or mounted volume. Attempting to download..."
        cd /opt/steamcmd
        wget -q https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
        tar -xzf steamcmd_linux.tar.gz
        rm steamcmd_linux.tar.gz
        chmod +x steamcmd.sh
        STEAMCMD_EXECUTABLE="/opt/steamcmd/steamcmd.sh"
    fi
fi

echo ">>> Executing steamcmd commands"
echo ">>> SteamCMD command: bash $STEAMCMD_EXECUTABLE +force_install_dir /opt/server/acesquared +login anonymous +app_update 3252540 validate +quit"
if timeout 300 bash $STEAMCMD_EXECUTABLE +force_install_dir /opt/server/acesquared +login anonymous +app_update 3252540 validate +quit; then
    echo ">>> SteamCMD update completed successfully"
else
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
fi

# Check if the game server binary exists before proceeding
if [ ! -f "/opt/server/acesquared/AceSquaredDedicated.x86_64" ]; then
    echo ">>> Error: Game server binary not found at /opt/server/acesquared/AceSquaredDedicated.x86_64"
    echo ">>> The download may have failed. Exiting..."
    exit 1
fi

# Optional: useful for troubleshooting
if [ -f "/opt/server/acesquared/AceSquaredDedicated.x86_64" ]; then
    ldd /opt/server/acesquared/AceSquaredDedicated.x86_64 || true
fi

# Copy steamclient.so for Unity to find via the Steam SDK path
STEAM_SDK_DIR="$HOME/.steam/sdk64"
PLUGIN_SRC="/opt/server/acesquared/AceSquaredDedicated.x86_64_Data/Plugins/steamclient.so"
PLUGIN_DST="$STEAM_SDK_DIR/steamclient.so"

# Only copy if both source and destination directories exist
if [ -f "$PLUGIN_SRC" ] && [ -d "$STEAM_SDK_DIR" ]; then
    echo ">>> Copying plugin from $PLUGIN_SRC to $PLUGIN_DST"
    cp -f "$PLUGIN_SRC" "$PLUGIN_DST"
else
    echo ">>> Warning: Could not copy steamclient.so. Source: $PLUGIN_SRC, Destination dir: $STEAM_SDK_DIR"
    if [ ! -f "$PLUGIN_SRC" ]; then
        echo ">>> Source file does not exist"
    fi
    if [ ! -d "$STEAM_SDK_DIR" ]; then
        echo ">>> Destination directory does not exist"
    fi
fi

echo ">>> Starting server as uid $(id -u) gid $(id -g) HOME=$HOME"
exec "/opt/server/acesquared/AceSquaredDedicated.x86_64"