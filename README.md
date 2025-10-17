# Ace Squared Dedicated Server Docker Setup

This repository provides a Docker setup for running the Ace Squared Dedicated Server. It includes a `Dockerfile` to build a containerized environment and a `start-server.sh` script that handles server startup and updates.

You should mount the files to local directory so server does not need to update unnecessarily, this way you may also e.g. inspect logs later or tweak configs. The server generates a default config file on first run, including default port numbers and other settings. Check the documentation website for more details.

## Features
- **Automated Startup and Updates:** The container uses `start-server.sh` as the entrypoint, which always starts the server via command-line (CMD) and attempts to update the server files if possible.
- **Volume Mounting:** Mount your local directory that should contain the Ace Squared game files to `/opt/server/acesquared` inside the container.

<br>
<br>


Build
```bash
sudo docker build -t acesquaredserver .
```


Example cmd to start the server:
```bash
sudo docker run -v "$PWD/br-obex-1:/opt/server/acesquared" \
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

Please note that you MUST forward the UDP ports used using the ```-p``` argument!<br>
These ports MUST be equal to the ports specified in the server config (config.toml)!


## Notes
- If you get weird error like "/usr/local/bin/start-server.sh: no such file or directory",
make sure to convert the script to have unix line endings.