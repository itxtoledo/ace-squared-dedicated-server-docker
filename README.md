# Ace Squared Dedicated Server Docker Setup

## Build

```bash
docker build -t acesquaredserver .
```

## Run

### On Linux x86_64 or Apple Silicon (M1/M2)
```bash
docker run -v "$PWD/br-obex-1:/opt/server/acesquared" \
-v "$PWD/files:/opt/steamcmd" \
--user $(id -u):$(id -g) \
-e HOME=/home/steam \
--name=br-obex-1 \
--restart unless-stopped \
--memory=2.5g \
-d \
-p 60010-60012:60010-60012/udp \
acesquaredserver
```

### On Apple Silicon with explicit platform (recommended for better performance)
```bash
docker run --platform linux/amd64 -v "$PWD/br-obex-1:/opt/server/acesquared" \
-v "$PWD/files:/opt/steamcmd" \
--user $(id -u):$(id -g) \
-e HOME=/home/steam \
--name=br-obex-1 \
--restart unless-stopped \
--memory=2.5g \
-d \
-p 60010-60012:60010-60012/udp \
acesquaredserver
```

## Command Explanation

- `docker run`: Creates and starts a new container from the specified image
- `-v "$PWD/br-obex-1:/opt/server/acesquared"`: Mounts the local directory "br-obex-1" (in current directory) to "/opt/server/acesquared" inside the container, where the game server files are stored. **br-obex-1 is the name of your server instance** - you can change this to any name you want for your server
- `-v "$PWD/files:/opt/steamcmd"`: Mounts a local "files" directory to persist SteamCMD data between runs
- `--user $(id -u):$(id -g)`: Runs the container as the current user instead of root, preventing file permission issues
- `-e HOME=/home/steam`: Sets the HOME environment variable inside the container
- `--name=br-obex-1`: Names the container "br-obex-1", making it easier to manage. **This should match the server name in the first volume mount**
- `--restart unless-stopped`: Automatically restarts the container if it crashes or the system reboots, but not if manually stopped
- `--memory=2.5g`: Limits the container's memory usage to 2.5GB
- `-d`: Runs the container in detached mode (in the background)
- `-p 60010-60012:60010-60012/udp`: Maps UDP ports 60010-60012 from the host to the container - these are the game server ports
- `acesquaredserver`: The name of the Docker image to use

Please note that you MUST forward the UDP ports used using the ```-p``` argument!<br>
These ports MUST be equal to the ports specified in the server config (config.toml)!

## Notes
- The Ace Squared server is a Unity x86_64 application, so it runs in an emulated x86_64 environment inside the container using Docker's QEMU emulation on ARM64 systems.
- Make sure Docker Desktop (on Mac) or Docker Engine (on Linux) has QEMU emulation enabled for multi-architecture support.
- If you get an error like "/usr/local/bin/start-server.sh: no such file or directory", make sure the script has Unix line endings.