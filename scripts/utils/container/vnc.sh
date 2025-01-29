#!/usr/bin/env bash

# Create VNC container
create_vnc() {
    run_quietly_if_ci echo "Starting VNC Server..."

    # Define path to the X11 socket directory
    X11_SOCKET="${ENV_ROOT}/${TEMP_DIR}/.X11-unix"
    export X11_SOCKET="${X11_SOCKET}"

    # Clean up any previous socket files and create a new directory
    remove_directory "${X11_SOCKET}"
    mkdir -p "${X11_SOCKET}"

    # Launch the VNC server container
    run_docker_container --detach \
        --network="${DOCKER_NETWORK}" \
        --name="vnc-server" \
        -p 5700:8080 \
        -e RUN_XTERM=no \
        -e DISPLAY_WIDTH=1920 \
        -e DISPLAY_HEIGHT=1080 \
        -v "${X11_SOCKET}:/tmp/.X11-unix" \
        "${VNC_REPO}:${VNC_TAG}" || error_exit "Failed to start VNC Server."
}
 