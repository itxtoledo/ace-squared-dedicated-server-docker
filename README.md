# Ace Squared Dedicated Server Docker Setup

This repository provides a Docker setup for running the Ace Squared Dedicated Server. It includes a `Dockerfile` to build a containerized environment and a `start-server.sh` script that handles server startup and updates.

You should mount the files to local directory so server does not need to update unnecessarily, this way you may also e.g. inspect logs later or tweak configs. The server generates a default config file on first run, including default port numbers and other settings. Check the documentation website for more details.

## Features
- **Automated Startup and Updates:** The container uses `start-server.sh` as the entrypoint, which always starts the server via command-line (CMD) and attempts to update the server files if possible.
- **Volume Mounting:** Mount your local directory that should contain the Ace Squared game files to `/opt/server/acesquared` inside the container.