#!/usr/bin/env bash
# Two-stage deployment: 1) infrastructure, 2) build the image, 3) create the app.
set -euo pipefail

LOCATION="swedencentral"
DEPLOYMENT="novatrix-main"
IMAGE="arendeapp:v1"      # bump the tag (v2, v3 ...) for new versions

# Resource providers required by Container Apps (no-op if already registered).
az provider register --namespace Microsoft.App --wait
az provider register --namespace Microsoft.OperationalInsights --wait

echo "== 1/3: infrastructure (without the app) =="
DEPLOY_APP=false IMAGE_NAME="$IMAGE" az deployment sub create \
  --name "$DEPLOYMENT" \
  --location "$LOCATION" \
  --template-file V40_main.bicep \
  --parameters V40_main.bicepparam

ACR=$(az deployment sub show --name "$DEPLOYMENT" --query properties.outputs.acrName.value -o tsv)

echo "== 2/3: building the image in $ACR =="
az acr build --registry "$ACR" --image "$IMAGE" ./app

echo "== 3/3: creating the container app =="
DEPLOY_APP=true IMAGE_NAME="$IMAGE" az deployment sub create \
  --name "$DEPLOYMENT" \
  --location "$LOCATION" \
  --template-file V40_main.bicep \
  --parameters V40_main.bicepparam

echo
echo "Done. App URL:"
az deployment sub show --name "$DEPLOYMENT" --query properties.outputs.appUrl.value -o tsv
