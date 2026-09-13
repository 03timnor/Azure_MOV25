#!/usr/bin/env bash
# Automated configuration of Novatrix web server

set -e

RESOURCE_GROUP="rg-novatrix"
LOCATION="swedencentral"
VM_NAME="VM-Novatrix-Web"
VM_SIZE="Standard_B2ats_v2"

VNET_NAME="vnet-novatrix"
VNET_PREFIX="10.0.0.0/16"
SUBNET_WEB_NAME="snet-web"
SUBNET_WEB_PREFIX="10.0.1.0/24"
SUBNET_DB_NAME="snet-db"
SUBNET_DB_PREFIX="10.0.2.0/24"
SUBNET_BASTION_NAME="AzureBastionSubnet"
SUBNET_BASTION_PREFIX="10.0.3.0/26"

NSG_WEB_NAME="nsg-web"

BASTION_NAME="bastion-novatrix"
BASTION_PIP_NAME="pip-bastion-novatrix"

# --- New: storage account for support tickets --------------------------------
# Storage account names must be globally unique, lowercase letters/digits only.
STORAGE_ACCOUNT="stnovatrix$(openssl rand -hex 4)"
CONTAINER_NAME="arenden"
# ------------------------------------------------------------------------------

# Some subscriptions (notably brand-new "Azure subscription 1" trial accounts
# created with a personal Microsoft/Gmail account) represent the owning user
# as a guest (#EXT#) identity internally. This trips a known "az role
# assignment create" bug that fails with "MissingSubscription" even with a
# fully valid --scope, no matter how --assignee is specified. The workaround
# used throughout this script is to call the ARM REST API directly via
# "az rest" instead, which takes a different code path and isn't affected.
SUBSCRIPTION_ID=$(az account show --query id -o tsv | tr -d '\r\n')
echo "  -> SUBSCRIPTION_ID=[$SUBSCRIPTION_ID]"

# Portable GUID generator (roleAssignments need a GUID as their resource name).
# Tries several tools since Git Bash on Windows often has neither uuidgen nor
# a real python3 (only the Microsoft Store alias stub) available.
generate_uuid() {
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen
  elif command -v python3 >/dev/null 2>&1 && python3 -c "import uuid" >/dev/null 2>&1; then
    python3 -c "import uuid; print(uuid.uuid4())"
  elif command -v python >/dev/null 2>&1 && python -c "import uuid" >/dev/null 2>&1; then
    python -c "import uuid; print(uuid.uuid4())"
  elif command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -Command "[guid]::NewGuid().ToString()" | tr -d '\r\n'
  else
    # Pure-bash fallback: build a v4-style GUID from /dev/urandom
    local hex nibble dec variant
    hex=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')
    nibble=${hex:16:1}
    dec=$(( (16#$nibble & 0x3) | 0x8 ))
    variant=$(printf '%x' "$dec")
    printf '%s-%s-4%s-%s%s-%s\n' \
      "${hex:0:8}" "${hex:8:4}" "${hex:13:3}" \
      "$variant" "${hex:17:3}" "${hex:20:12}"
  fi
}

# assign_role <principal-id> <principal-type: User|ServicePrincipal> <scope>
assign_role() {
  local principal_id="$1"
  local principal_type="$2"
  local scope="$3"
  local assignment_id body_file

  assignment_id=$(generate_uuid)
  body_file="$(mktemp /tmp/roleassign.XXXXXX.json)"

  cat > "$body_file" <<JSONEOF
{
  "properties": {
    "roleDefinitionId": "${ROLE_DEF_ID}",
    "principalId": "${principal_id}",
    "principalType": "${principal_type}"
  }
}
JSONEOF

  az rest --method PUT \
    --url "https://management.azure.com${scope}/providers/Microsoft.Authorization/roleAssignments/${assignment_id}?api-version=2022-04-01" \
    --body @"$body_file"

  rm -f "$body_file"
}

echo "Creating resource group..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

echo "Creating storage account $STORAGE_ACCOUNT..."
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --allow-shared-key-access false

STORAGE_ID=$(az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query id -o tsv | tr -d '\r\n')

if [ -z "$STORAGE_ID" ]; then
  echo "ERROR: could not resolve the resource ID for storage account '$STORAGE_ACCOUNT'." >&2
  echo "Check that 'az account show' points at the subscription where '$RESOURCE_GROUP' lives" >&2
  echo "(run 'az account set --subscription <name-or-id>' if you have more than one)." >&2
  exit 1
fi
echo "  -> STORAGE_ID=[$STORAGE_ID]"

ROLE_DEF_ID=$(az role definition list --name "Storage Blob Data Contributor" --query "[0].id" -o tsv | tr -d '\r\n')
if [ -z "$ROLE_DEF_ID" ]; then
  echo "ERROR: could not resolve role definition id for 'Storage Blob Data Contributor'." >&2
  exit 1
fi
echo "  -> ROLE_DEF_ID=[$ROLE_DEF_ID]"

echo "Granting your own Azure AD identity access to create the container..."
# No account key is used anywhere in this script. Instead, your own signed-in
# identity (az login) is granted data-plane access so the container can be
# created with Azure AD auth (--auth-mode login).
CALLER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv | tr -d '\r\n')

if [ -z "$CALLER_OBJECT_ID" ]; then
  echo "ERROR: could not resolve your signed-in Azure AD object id." >&2
  echo "Make sure you're logged in with 'az login' as a regular user account." >&2
  exit 1
fi
echo "  -> CALLER_OBJECT_ID=[$CALLER_OBJECT_ID]"

assign_role "$CALLER_OBJECT_ID" "User" "$STORAGE_ID"

# RBAC role assignments can take a short while to propagate before they're
# usable, so give it a moment before the first data-plane call.
sleep 30

echo "Creating container $CONTAINER_NAME..."
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login

echo "Creating VNet with snet-web subnet..."
az network vnet create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VNET_NAME" \
  --address-prefix "$VNET_PREFIX" \
  --subnet-name "$SUBNET_WEB_NAME" \
  --subnet-prefix "$SUBNET_WEB_PREFIX"

echo "Creating snet-db subnet..."
az network vnet subnet create \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_DB_NAME" \
  --address-prefix "$SUBNET_DB_PREFIX"

echo "Creating AzureBastionSubnet..."
az network vnet subnet create \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_BASTION_NAME" \
  --address-prefix "$SUBNET_BASTION_PREFIX"

echo "Creating NSG nsg-web..."
az network nsg create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$NSG_WEB_NAME"

echo "Adding rule to allow HTTP (80) from the internet..."
az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$NSG_WEB_NAME" \
  --name "Allow-HTTP" \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes Internet \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 80

echo "Adding rule to allow HTTPS (443) from the internet..."
az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$NSG_WEB_NAME" \
  --name "Allow-HTTPS" \
  --priority 150 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes Internet \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 443

echo "Associating nsg-web with snet-web..."
az network vnet subnet update \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_WEB_NAME" \
  --network-security-group "$NSG_WEB_NAME"

echo "Creating public IP for Azure Bastion..."
az network public-ip create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$BASTION_PIP_NAME" \
  --sku Standard \
  --location "$LOCATION"

echo "Creating Azure Bastion host (Standard SKU with native client support, this can take several minutes)..."
az network bastion create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$BASTION_NAME" \
  --vnet-name "$VNET_NAME" \
  --public-ip-address "$BASTION_PIP_NAME" \
  --location "$LOCATION" \
  --sku Standard \
  --enable-tunneling true

echo "Injecting the generated storage account name into cloud-init.yaml..."
# cloud-init.yaml is static and was written before this script ran, so it
# still contains the placeholder account name from app.py. We patch a copy
# of it with the real, randomly generated $STORAGE_ACCOUNT before boot.
# Adjust the placeholder text below if yours differs from "stnovatrixXXXX".
PLACEHOLDER="stnovatrixXXXX"
PATCHED_CLOUD_INIT="$(mktemp /tmp/cloud-init.XXXXXX.yaml)"
trap 'rm -f "$PATCHED_CLOUD_INIT"' EXIT

sed "s/${PLACEHOLDER}/${STORAGE_ACCOUNT}/g" cloud-init.yaml > "$PATCHED_CLOUD_INIT"

echo "Creating virtual machine with cloud-init..."
# --assign-identity gives the VM a system-assigned Managed Identity.
az vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --image Ubuntu2204 \
  --size "$VM_SIZE" \
  --admin-username azureuser \
  --generate-ssh-keys \
  --custom-data "$PATCHED_CLOUD_INIT" \
  --vnet-name "$VNET_NAME" \
  --subnet "$SUBNET_WEB_NAME" \
  --nsg "$NSG_WEB_NAME" \
  --public-ip-sku Standard \
  --assign-identity

echo "Granting the VM's Managed Identity access to the '$CONTAINER_NAME' container only..."
VM_PRINCIPAL_ID=$(az vm identity show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --query principalId -o tsv | tr -d '\r\n')

if [ -z "$VM_PRINCIPAL_ID" ]; then
  echo "ERROR: could not resolve the VM's managed identity principal id." >&2
  exit 1
fi
echo "  -> VM_PRINCIPAL_ID=[$VM_PRINCIPAL_ID]"

CONTAINER_SCOPE="${STORAGE_ID}/blobServices/default/containers/${CONTAINER_NAME}"
echo "  -> CONTAINER_SCOPE=[$CONTAINER_SCOPE]"

assign_role "$VM_PRINCIPAL_ID" "ServicePrincipal" "$CONTAINER_SCOPE"

echo "Done! Storage account: $STORAGE_ACCOUNT (container: $CONTAINER_NAME)"
echo "app.py on the VM has been patched with this account name automatically."
echo "Note: role assignment propagation can take a couple of minutes -"
echo "if the app briefly gets an auth error right after boot, just retry."

echo "Public IP:"
az vm show -d \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --query publicIps -o tsv

echo "To connect via Bastion from your local terminal, run:"
echo "az network bastion ssh --name $BASTION_NAME --resource-group $RESOURCE_GROUP --target-resource-id \$(az vm show -g $RESOURCE_GROUP -n $VM_NAME --query id -o tsv) --auth-type ssh-key --username azureuser --ssh-key ~/.ssh/id_rsa"