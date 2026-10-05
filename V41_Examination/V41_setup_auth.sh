#!/usr/bin/env bash
# Creates (or updates) the Entra ID app registration the portal signs users in with,
# and prints the two values the Bicep deployment needs.
#
# Run after the FIRST deployment (infrastructure, DEPLOY_APP=false) and before the
# second one (DEPLOY_APP=true). The redirect URI can be computed already then,
# because the Container Apps environment exists.
#
#   ENVIRONMENT_TYPE=prod ./V41_setup_auth.sh
#
# Needs: az login with permission to create app registrations in the tenant.
set -euo pipefail

ENV_TYPE="${ENVIRONMENT_TYPE:-prod}"
RG="${RESOURCE_GROUP:-rg-nordvik-${ENV_TYPE}}"
ENV_NAME="${ENV_NAME:-cae-nordvik-${ENV_TYPE}}"
APP_NAME="${APP_NAME:-ca-nordvik-portal-${ENV_TYPE}}"
DISPLAY_NAME="Nordvik portal (${ENV_TYPE})"

DOMAIN=$(az containerapp env show -g "$RG" -n "$ENV_NAME" --query properties.defaultDomain -o tsv)
REDIRECT="https://${APP_NAME}.${DOMAIN}/.auth/login/nordvik/callback"

APP_ID=$(az ad app list --display-name "$DISPLAY_NAME" --query "[0].appId" -o tsv)
if [ -z "$APP_ID" ]; then
  APP_ID=$(az ad app create --display-name "$DISPLAY_NAME" \
    --sign-in-audience AzureADMyOrg \
    --web-redirect-uris "$REDIRECT" \
    --enable-id-token-issuance true \
    --query appId -o tsv)
else
  az ad app update --id "$APP_ID" --web-redirect-uris "$REDIRECT" --enable-id-token-issuance true >/dev/null
fi

# The enterprise application (service principal) is what lets users sign in.
if [ -z "$(az ad sp list --filter "appId eq '$APP_ID'" --query "[0].id" -o tsv)" ]; then
  az ad sp create --id "$APP_ID" >/dev/null
fi

# A new secret replaces older ones. Valid for one year.
SECRET=$(az ad app credential reset --id "$APP_ID" --display-name "nordvik-portal" --years 1 --query password -o tsv)

echo "Redirect URI: $REDIRECT" >&2
echo "Copy these into your shell before the second deployment (the secret is shown only once):" >&2
echo "export OIDC_CLIENT_ID='$APP_ID'"
echo "export OIDC_CLIENT_SECRET='$SECRET'"
