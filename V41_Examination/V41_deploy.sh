#!/usr/bin/env bash
# Deploys the Nordvik portal in the right order.
#
#   ./V41_deploy.sh [stage]
#
# Stages (default: all)
#   validate  Check the Bicep files against Azure without changing anything
#   infra     Deployment 1: network, storage, registry, mail, roles (no app yet)
#   image     Build the container image in the registry (az acr build)
#   auth      Create the Entra app registration (skipped in demo mode)
#   app       Deployment 2: container app + notification job
#   all       infra -> image -> auth -> app
#
# Environment variables (all optional)
#   ENVIRONMENT_TYPE  prod (default) | test | demo
#   DEMO_MODE         true = fake demo users instead of real sign-in (not in prod)
#   LOCATION          Azure region for the deployment record (default swedencentral)
#   IMAGE_NAME        Image and tag, e.g. portal:v7. Default: portal:<timestamp>
#   FLOW_URL          Power Automate trigger URL (kept out of files on purpose)
#   OIDC_CLIENT_ID    Reuse an existing app registration (otherwise
#                     V41_setup_auth.sh creates one in stage "auth"; no secret is used)
#   SEED_USERS        true = load V41_users.csv / V41_properties.csv after "app"
#                     (needs allowedIpAddress set in V41_main.bicepparam)
#
# Examples
#   ./V41_deploy.sh                                   # production
#   ENVIRONMENT_TYPE=demo DEMO_MODE=true ./V41_deploy.sh   # demo environment
#   ./V41_deploy.sh image && ./V41_deploy.sh app      # new version only
set -euo pipefail
cd "$(dirname "$0")"

STAGE="${1:-all}"
export ENVIRONMENT_TYPE="${ENVIRONMENT_TYPE:-prod}"
export DEMO_MODE="${DEMO_MODE:-false}"
LOCATION="${LOCATION:-swedencentral}"
DEPLOY_NAME="nordvik-${ENVIRONMENT_TYPE}"
IMAGE_FILE=".v41_image_${ENVIRONMENT_TYPE}"

log() { printf '\n== %s\n' "$*" >&2; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

preflight() {
  command -v az >/dev/null || die "Azure CLI (az) is not installed."
  az account show >/dev/null 2>&1 || die "Run 'az login' first."
  [ "$ENVIRONMENT_TYPE" = "prod" ] && [ "$DEMO_MODE" = "true" ] && die "DEMO_MODE is not allowed in prod."
  if grep -qE "^param (callerObjectId|allowedIpAddress) = 'placeholder'" V41_main.bicepparam; then
    die "V41_main.bicepparam still contains 'placeholder' values. Fill them in (or set them to '')."
  fi
  # Fail early if a built-in role GUID in the Bicep file does not exist in this tenant.
  local g name bad=0
  for g in $(grep -oE "roleDefinitions', '[0-9a-f-]{36}'" V41_resources.bicep | grep -oE "[0-9a-f-]{36}" | sort -u); do
    name=$(az role definition list --name "$g" --query "[0].roleName" -o tsv 2>/dev/null || true)
    if [ -z "$name" ]; then echo "ERROR: role definition $g does not exist (check V41_resources.bicep)" >&2; bad=1
    else echo "role ok: $name" >&2; fi
  done
  [ "$bad" = 0 ] || die "Fix the role GUIDs above first."
  az extension add --name containerapp --upgrade --only-show-errors -y >/dev/null 2>&1 || true
  log "Subscription: $(az account show --query name -o tsv) | environment: $ENVIRONMENT_TYPE | demo: $DEMO_MODE"
}

deploy() {  # $1 = true|false (deploy the app and job?)
  export DEPLOY_APP="$1"
  [ "$DEPLOY_APP" = "true" ] && export IMAGE_NAME="$(cat "$IMAGE_FILE" 2>/dev/null || true)"
  [ "$DEPLOY_APP" = "true" ] && [ -z "$IMAGE_NAME" ] && die "No image built yet. Run './V41_deploy.sh image' first."
  export IMAGE_NAME="${IMAGE_NAME:-portal:v1}"
  local attempt
  for attempt in 1 2; do
    if az deployment sub create --name "$DEPLOY_NAME" --location "$LOCATION" \
         --parameters V41_main.bicepparam --only-show-errors -o none; then
      return 0
    fi
    # Freshly created role assignments (AcrPull) can take a minute to propagate.
    [ "$attempt" = 1 ] && [ "$DEPLOY_APP" = "true" ] && { log "Deployment failed, retrying once in 60 s"; sleep 60; }
  done
  die "Deployment failed."
}

output() { az deployment sub show --name "$DEPLOY_NAME" --query "properties.outputs.$1.value" -o tsv; }

stage_validate() {
  export DEPLOY_APP=false IMAGE_NAME="${IMAGE_NAME:-portal:v1}"
  log "Validating"
  az deployment sub validate --name "$DEPLOY_NAME" --location "$LOCATION" \
    --parameters V41_main.bicepparam --only-show-errors -o none
  echo "Validation OK" >&2
}

stage_infra() {
  log "Deployment 1: infrastructure"
  deploy false
  echo "Storage account: $(output storageAccountName)" >&2
  echo "Registry:        $(output acrName)" >&2
}

stage_image() {
  local acr tag
  acr="$(output acrName)" || die "Run the 'infra' stage first."
  tag="${IMAGE_NAME:-portal:$(date +%Y%m%d%H%M%S)}"
  log "Building image $tag in registry $acr"
  az acr build --registry "$acr" --image "$tag" --file Dockerfile . --only-show-errors
  echo "$tag" > "$IMAGE_FILE"
}

stage_auth() {
  if [ "$DEMO_MODE" = "true" ]; then log "Demo mode: skipping sign-in setup"; return; fi
  if [ -n "${OIDC_CLIENT_ID:-}" ]; then
    log "Using OIDC_CLIENT_ID from the environment"; return
  fi
  log "Creating the Entra app registration"
  eval "$(./V41_setup_auth.sh)"
  export OIDC_CLIENT_ID
}

stage_app() {
  log "Deployment 2: container app and notification job"
  deploy true
  echo >&2
  echo "Portal:         $(output appUrl)" >&2
  echo "Mail sender:    $(output mailSender)" >&2
  [ "$DEMO_MODE" = "true" ] || echo "Redirect URI:   $(output oidcRedirectUri)  (set by V41_setup_auth.sh)" >&2
  if [ "${SEED_USERS:-false}" = "true" ]; then
    log "Loading users and properties"
    ./V41_seed_users.sh V41_users.csv V41_properties.csv
  fi
}

preflight
case "$STAGE" in
  validate) stage_validate ;;
  infra)    stage_infra ;;
  image)    stage_image ;;
  auth)     stage_auth; [ -n "${OIDC_CLIENT_ID:-}" ] && echo "Export OIDC_CLIENT_ID (printed above) before running 'app'." >&2 ;;
  app)      stage_app ;;
  all)      stage_infra; stage_image; stage_auth; stage_app ;;
  *)        die "Unknown stage '$STAGE'. Use: validate | infra | image | auth | app | all" ;;
esac
log "Done: $STAGE"
