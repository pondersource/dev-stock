#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Reva Daemon Termination Script
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
# -----------------------------------------------------------------------------------

# Description:
#   This script searches for any running Reva daemon (revad) processes and terminates them.
#   It ensures a clean shutdown in development or testing environments where revad
#   might still be running in the background.
#
# Requirements:
#   - pgrep and kill must be installed and available in PATH.
#   - The script assumes only one revad process is actively running or that the last started
#     revad process is the one needing termination.
#
# Behavior:
#   - Finds the PID of the most recently started revad process using `pgrep -f "revad" | tail -n 1`.
#   - If no PID is found, it prints a message and exits successfully.
#   - If a PID is found, it sends a SIGKILL (kill -9) to force-stop the process.
#   - Logs the action taken to stdout.
#
# Notes:
#   - Using `kill -9` is forceful; consider using a gentler signal (e.g., SIGTERM) in production.
#   - This script is primarily intended for development/testing cleanup.
#
# Exit Codes:
#   0 - Success or no revad processes found.
#   1 - Failure to terminate the found revad process.
#
# Example:
#   ./terminate.sh
#
# -----------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------
# Exit on Errors and Treat Unset Variables as Errors
# -----------------------------------------------------------------------------------
set -euo pipefail

# -----------------------------------------------------------------------------------
# Function: terminate_revad
# Purpose: Safely terminate any running revad process.
# Process:
#   1. Searches for revad processes using `pgrep -f "revad"`.
#   2. Picks the most recently started revad process (tail -n 1).
#   3. Sends a SIGKILL (kill -9) to the process.
# Returns:
#   0 if no process was found or termination was successful,
#   1 if it failed to terminate the process.
# -----------------------------------------------------------------------------------
terminate_revad() {
    # Find the PID of the most recently started revad process
    local revad_pid

    revad_pid=$(pgrep -f "revad" | tail -n 1 || true)

    # Check if a PID was found
    if [[ -z "$revad_pid" ]]; then
        printf "No running revad process found.\n"
        return 0
    fi

    # Safely terminate the revad process using kill -9
    printf "Terminating revad process with PID %s...\n" "$revad_pid"
    if ! kill -9 "$revad_pid" 2>/dev/null; then
        printf "Error: Failed to terminate revad process with PID %s.\n" "$revad_pid" >&2
        return 1
    fi

    printf "Successfully terminated revad process with PID %s.\n" "$revad_pid"
    return 0
}

# -----------------------------------------------------------------------------------
# Main function to coordinate script execution
# -----------------------------------------------------------------------------------
main() {
    terminate_revad
}

# -----------------------------------------------------------------------------------
# Execute the main function
# -----------------------------------------------------------------------------------
main
