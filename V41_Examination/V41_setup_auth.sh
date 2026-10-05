#!/usr/bin/env bash
# Creates (or updates) the Entra ID app registration the portal signs users in with,
# WITHOUT a client secret: the registration trusts the portal's managed identity
# (federated identity credential). Prints the one value the Bicep deployment needs.
#
# Run after the FIRST deployment (infrastructure, DEPLOY_APP=false) and before the
# second one (DEPLOY_APP=true). The managed identity and the Container Apps
# environment exist by then, so redirect URI and trust can be set up already.
#
#   ENVIRONMENT_TYPE=prod ./V41_setup_auth.sh
#
# Needs: az login with permission to create app registrations in the tenant.
set -euo pipefail

ENV_TYPE="${ENVIRONMENT_TYPE:-prod}"
RG="${RESOURCE_GROUP:-rg-nordvik-${ENV_TYPE}}"
ENV_NAME="${ENV_NAME:-cae-nordvik-${ENV_TYPE}}"
APP_NAME="${APP_NAME:-ca-nordvik-portal-${ENV_TYPE}}"
IDENTITY_NAME="${IDENTITY_NAME:-id-${APP_NAME}}"
DISPLAY_NAME="Nordvik portal (${ENV_TYPE})"
FIC_NAME="nordvik-portal-managed-identity"

TENANT_ID=$(az account show --query tenantId -o tsv)
DOMAIN=$(az containerapp env show -g "$RG" -n "$ENV_NAME" --query properties.defaultDomain -o tsv)
MI_PRINCIPAL_ID=$(az identity show -g "$RG" -n "$IDENTITY_NAME" --query principalId -o tsv)
REDIRECT="https://${APP_NAME}.${DOMAIN}/.auth/login/aad/callback"

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

# Trust the managed identity instead of a secret: issuer = this tenant, subject = the
# identity's principal (object) ID, audience = the fixed Entra token exchange value.
for existing in $(az ad app federated-credential list --id "$APP_ID" --query "[?name=='$FIC_NAME'].id" -o tsv); do
  az ad app federated-credential delete --id "$APP_ID" --federated-credential-id "$existing" >/dev/null
done
az ad app federated-credential create --id "$APP_ID" --parameters "{
  \"name\": \"$FIC_NAME\",
  \"issuer\": \"https://login.microsoftonline.com/${TENANT_ID}/v2.0\",
  \"subject\": \"${MI_PRINCIPAL_ID}\",
  \"audiences\": [\"api://AzureADTokenExchange\"]
}" >/dev/null

echo "Redirect URI:  $REDIRECT" >&2
echo "Trusted identity: $IDENTITY_NAME ($MI_PRINCIPAL_ID)" >&2
echo "No client secret was created. Export this before the second deployment:" >&2
echo "export OIDC_CLIENT_ID='$APP_ID'"
