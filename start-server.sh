#!/bin/bash
set -euo pipefail

echo "Running with UID: $(id -u), GID: $(id -g)"

export HOME="${HOME:-/home/steam}"
mkdir -p "$HOME/.steam/sdk64"

# STEAMCMD_BUILT_IN is where SteamCMD was installed during Docker image build
STEAMCMD_BUILT_IN="/opt/steamcmd-installed"
STEAMCMD_MOUNTED="/opt/steamcmd"

STEAMCMD_EXECUTABLE=""

# Check if steamcmd exists in the mounted volume (user's files directory)
if [ -f "$STEAMCMD_MOUNTED/steamcmd.sh" ]; then
    # If volume is mounted with existing SteamCMD files, use those
    echo ">>> SteamCMD found in mounted volume, using that version"
    STEAMCMD_EXECUTABLE="$STEAMCMD_MOUNTED/steamcmd.sh"
else
    # If volume is empty (no SteamCMD files), use the built-in one from image build
    if [ -f "$STEAMCMD_BUILT_IN/steamcmd.sh" ]; then
        echo ">>> SteamCMD not found in mounted volume, using built-in version from image"
        # Copy the built-in SteamCMD to the mounted volume for persistence
        cp -r $STEAMCMD_BUILT_IN/* $STEAMCMD_MOUNTED/ 2>/dev/null || true
        # Wait a moment for the copy to complete
        sleep 1
        STEAMCMD_EXECUTABLE="$STEAMCMD_MOUNTED/steamcmd.sh"
    else
        echo ">>> No SteamCMD found in built-in location. This should not happen. Exiting..."
        exit 1
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