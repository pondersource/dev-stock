#!/usr/bin/env bash

# Function to check if a command exists
command_exists() {
    command -v "${1}" >/dev/null 2>&1
}

# Ensure required commands are available
ensure_required_commands() {
    for cmd in docker; do
        if ! command_exists "${cmd}"; then
            error_exit "Required command '${cmd}' is not available. Please install it and try again."
        fi
    done
}

# Ensure Docker daemon is running
ensure_docker_running() {
    if ! docker info >/dev/null 2>&1; then
        error_exit "Cannot connect to the Docker daemon. Is it running and do you have the right permissions?"
    fi
}

# Remove directory if it exists
remove_directory() {
    local dir="${1}"
    if [ -d "${dir}" ]; then
        run_quietly_if_ci rm -rf "${dir}" || error_exit "Failed to remove directory: ${dir}"
    fi
}

# Wait for a Docker container port to be available
wait_for_port() {
    local container="${1}"
    local port="${2}"
    local timeout=60  # Maximum wait time in seconds
    local start_time=$(date +%s)

    run_quietly_if_ci echo "Waiting for port ${port} on container ${container}..."
    while true; do
        if docker exec "${container}" sh -c "ss -tulpn | grep -q 'LISTEN.*:${port}'" >/dev/null 2>&1; then
            run_quietly_if_ci echo "Port ${port} is now open on ${container}."
            return 0
        fi

        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))
        
        if [ ${elapsed_time} -ge ${timeout} ]; then
            error_exit "Timeout waiting for port ${port} on container ${container} after ${timeout} seconds"
        fi

        run_quietly_if_ci echo "Port ${port} not open yet on ${container}. Retrying..."
        sleep 1
    done
}
