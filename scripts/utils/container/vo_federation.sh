#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Function: configure_vo_federation
# Purpose: Configure VO Federation app settings for the EFSS platform.
# Arguments:
#   $1 - EFSS platform (e.g., nextcloud).
#   $2 - Instance number.
#   $3 - Identifier for the Keycloak OIDC provider.
#   $4 - Client ID for the KeycloakOIDC provider.
#   $5 - Client secret for the Keycloak OIDC provider.
#   $6 - Keycloak realm URL.
#   $7 - Trusted instances (space-separated list of URLs).

# -----------------------------------------------------------------------------------
configure_vo_federation() {
    local platform="${1}"
    local number="${2}"
    local identifier="${3}"
    local clientid="${4}"
    local clientsecret="${5}"
    local kc_realm_url="${6}"
    local trusted_instances="${7}"
    run_quietly_if_ci echo "Configuring VO Federation app for ${platform} ${number}"

    local occ_cmd="docker exec ${platform}${number}.docker php /var/www/html/occ"

    # Enable remote group sharing
    run_quietly_if_ci $occ_cmd config:app:set files_sharing incoming_server2server_group_share_enabled --value="yes"
    run_quietly_if_ci $occ_cmd config:app:set files_sharing outgoing_server2server_group_share_enabled --value="yes"

    # Add Community AAI with trusted instances
    run_quietly_if_ci $occ_cmd vo_federation:provider:add $identifier \
        --clientid="${clientid}" \
        --clientsecret="${clientsecret}" \
        --authorization-endpoint="${kc_realm_url}/protocol/openid-connect/auth" \
        --token-endpoint="${kc_realm_url}/protocol/openid-connect/token" \
        --jwks-endpoint="${kc_realm_url}/protocol/openid-connect/certs" \
        --userinfo-endpoint="${kc_realm_url}/protocol/openid-connect/userinfo" \
        --scope="openid email profile groups" \
        --mapping-uid="sub" \
        --mapping-display-name="preferred_username" \
        --mapping-groups="groups" \
        --regex-pattern=".*" \
        $(for url in ${trusted_instances}; do echo "--trusted-instance=${url} "; done)
}
