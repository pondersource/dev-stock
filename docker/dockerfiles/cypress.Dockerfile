FROM cypress/included:13.13.1@sha256:e9bb8aa3e4cca25867c1bdb09bd0a334957fc26ec25239534e6909697efb297e

# Copy test suite files
COPY cypress/ocm-test-suite/ /ocm
