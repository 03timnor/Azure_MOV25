#!/bin/bash
export MSYS_NO_PATHCONV=1

# Exit immediately if any command fails
set -e

# 1. Define your local file name and target Resource Group
JSON_FILE="placeholder.json"
RG_NAME="rg-placeholder"
ROLE_NAME="placeholder"

# Check if the JSON file actually exists locally
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: Local file $JSON_FILE not found in the current directory."
    exit 1
fi

# 2. Fetch the active Azure Subscription ID automatically
echo "Fetching active Azure Subscription ID..."
SUBSCRIPTION_ID=$(az account show --query id --output tsv 2>/dev/null || true)

if [ -z "$SUBSCRIPTION_ID" ]; then
    echo "Error: Not logged into Azure. Please run 'az login' first."
    exit 1
fi
az account set --subscription "$SUBSCRIPTION_ID"

# 3. Use jq to dynamically inject the correct scope into the JSON file
echo "Updating AssignableScopes inside $JSON_FILE..."
TARGET_SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME"

# This updates the JSON in-place with the correct subscription and resource group path
jq --arg scope "$TARGET_SCOPE" '.AssignableScopes = [$scope]' "$JSON_FILE" > temp.json && mv temp.json "$JSON_FILE"

# 4. Check if the role already exists in Azure to determine Create vs Update
echo "Checking if role '$ROLE_NAME' already exists in your tenant..."
ROLE_EXISTS=$(az role definition list --name "$ROLE_NAME" --query "[0].name" --output tsv)

if [ "$ROLE_EXISTS" == "$ROLE_NAME" ]; then
    echo "Role already exists. Executing update..."
    az role definition update --role-definition "@$JSON_FILE"
    echo "Successfully updated custom RBAC role!"
else
    echo "Role does not exist. Executing creation..."
    az role definition create --role-definition "@$JSON_FILE"
    echo "Successfully created custom RBAC role!"
fi
