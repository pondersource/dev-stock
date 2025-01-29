#!/usr/bin/env bash


# Print OCM test setup instructions
print_setup_core() {
    echo ""
    echo "Development environment setup complete."
    echo "Access the following URLs in your browser:"
    echo "  Embedded Firefox          -> http://localhost:5800"
}

# Print OCM test setup instructions
print_development_instructions() {
    print_setup_core
    echo "Log in to EFSS platforms using the following credentials:"
}

# Print OCM test setup instructions
print_ocm_test_setup_instructions() {
    print_setup_core
    echo "  Cypress inside VNC Server -> http://localhost:5700/vnc.html"
    echo "Note:"
    echo "  Scale VNC to get to the Continue button, and run the appropriate test from ./cypress/ocm-test-suite/cypress/e2e/"
    echo ""
    echo "Log in to EFSS platforms using the following credentials:"
}

# Run development mode
run_dev() {
    local url_line_1="${1}"
    local url_line_2="${2}"

    # Quiet log in CI mode
    run_quietly_if_ci echo "Setting up development environment..."

    # Create containers for Firefox, VNC, and Cypress (dev mode)
    create_firefox
    create_vnc
    create_cypress_dev

    # Display setup instructions
    print_ocm_test_setup_instructions

    # Echo the two lines passed as arguments
    echo "  ${url_line_1}"
    echo "  ${url_line_2}"
}
