#!/bin/bash
set -euo pipefail

# Verify that the mounted volume is writable
if [ ! -w "/opt/steamcmd" ]; then
    echo "Error: The directory /opt/steamcmd (your local 'files' directory) is not writable by the container." >&2
    echo "Please ensure the 'files' directory exists and you have write permissions." >&2
    echo "On Linux/macOS, you can fix this by running: mkdir -p files && sudo chown $(id -u):$(id -g) files" >&2
    exit 1
fi

# Verify that the game server mounted volume is writable
if [ ! -w "/opt/server/acesquared" ]; then
    echo "Error: The directory /opt/server/acesquared (your local 'br-obex-1' directory) is not writable by the container." >&2
    echo "Please ensure the 'br-obex-1' directory exists and you have write permissions." >&2
    echo "On Linux/macOS, you can fix this by running: mkdir -p br-obex-1 && sudo chown $(id -u):$(id -g) br-obex-1" >&2
    exit 1
fi

echo "Running with UID: $(id -u), GID: $(id -g)"

export HOME="${HOME:-/home/steam}"
mkdir -p "$HOME/.steam/sdk64"

STEAMCMD_MOUNTED="/opt/steamcmd"
STEAMCMD_EXECUTABLE="$STEAMCMD_MOUNTED/steamcmd.sh"

# Check if steamcmd.sh exists in the mounted volume. If not, download it.
if [ ! -f "$STEAMCMD_EXECUTABLE" ]; then
    echo ">>> SteamCMD not found in mounted volume. Downloading..."
    
    # Create the directory if it doesn't exist
    mkdir -p "$STEAMCMD_MOUNTED"
    
    # Download, extract, and set permissions for SteamCMD
    wget -q https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz -P "$STEAMCMD_MOUNTED"
    tar -xzf "$STEAMCMD_MOUNTED/steamcmd_linux.tar.gz" -C "$STEAMCMD_MOUNTED"
    rm "$STEAMCMD_MOUNTED/steamcmd_linux.tar.gz"
    
    echo ">>> Granting execute permissions to SteamCMD..."
    chmod +x "$STEAMCMD_EXECUTABLE"
    
    # Also grant execute permission for the 32-bit compatibility layer if it exists
    if [ -f "$STEAMCMD_MOUNTED/linux32/steamcmd" ]; then
        chmod +x "$STEAMCMD_MOUNTED/linux32/steamcmd"
    fi
    
    echo ">>> SteamCMD downloaded and installed successfully."
else
    echo ">>> SteamCMD found in mounted volume, using that version."
fi

echo ">>> Executing steamcmd commands to update the server"
echo ">>> SteamCMD command: bash $STEAMCMD_EXECUTABLE +force_install_dir /opt/server/acesquared +login anonymous +app_update 3252540 validate +quit"
if timeout 300 bash $STEAMCMD_EXECUTABLE +force_install_dir /opt/server/acesquared +login anonymous +app_update 3252540 validate +quit; then
    echo ">>> SteamCMD update completed successfully"
else
    echo ">>> SteamCMD execution failed or timed out. This could be due to network issues or other problems."
    echo ">>> Error: Could not update the game server."
    # Verificar se os arquivos do servidor existem mesmo após falha na atualização
    if [ -f "/opt/server/acesquared/AceSquaredDedicated.x86_64" ]; then
        echo ">>> Game server files detected, proceeding to start server with existing files..."
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
PLUGIN_DST="$STEAM_SDK_DIR/steamclient.so"

# Find the actual steamclient.so file
FOUND_PLUGIN_SRC=$(find /opt/server/acesquared -name "steamclient.so" -type f -print -quit)

if [ -n "$FOUND_PLUGIN_SRC" ]; then # Check if FOUND_PLUGIN_SRC is not empty
    echo "Found steamclient.so at: $FOUND_PLUGIN_SRC"
    if [ -d "$STEAM_SDK_DIR" ]; then
        cp -f "$FOUND_PLUGIN_SRC" "$PLUGIN_DST"
    else
        # STEAM_SDK_DIR should always exist here as it's created earlier.
    fi
else
    echo ">>> Warning: Could not find steamclient.so within /opt/server/acesquared. Copy operation skipped."
fi

exec "/opt/server/acesquared/AceSquaredDedicated.x86_64"