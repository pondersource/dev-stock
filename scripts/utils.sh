#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Main utility script that sources all modular components
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
# -----------------------------------------------------------------------------------

# Exit on error, undefined vars, and pipe failures
set -euo pipefail

# Store the directory of utils.sh
UTILS_DIR="${ENV_ROOT}/scripts"
MODULES_DIR="${UTILS_DIR}/utils"

# Function to source a module
source_module() {
    local module="$1"
    if [[ -f "${MODULES_DIR}/${module}" ]]; then
        # shellcheck source=/dev/null
        source "${MODULES_DIR}/${module}"
    else
        echo "Error: Module '${module}' not found" >&2
        exit 1
    fi
}

# Source all base modules
source_module "constants.sh"
source_module "errors.sh"
source_module "environment.sh"
source_module "docker.sh"
source_module "validation.sh"
source_module "setup.sh"

# Source container modules
for module in "${MODULES_DIR}/container"/*.sh; do
    # shellcheck source=/dev/null
    source "$module"
done

# Source test mode modules
for module in "${MODULES_DIR}/test_modes"/*.sh; do
    # shellcheck source=/dev/null
    source "$module"
done

# Export the version variables passed from the main script
DEFAULT_EFSS_1_VERSION="${1}"
DEFAULT_EFSS_2_VERSION="${2}"
export DEFAULT_EFSS_1_VERSION
export DEFAULT_EFSS_2_VERSION 
