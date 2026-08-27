# 1. Prevent Git Bash path parsing corruptions
export MSYS_NO_PATHCONV=1

# 2. Define your exact targets
RG_NAME="placeholder"
GROUP_NAME="placeholder"
ROLE_NAME="placeholder"

# 3. Pull required parameters dynamically from your current session
SUB_ID=$(az account show --query id --output tsv)
GROUP_OBJECT_ID=$(az ad group show --group "$GROUP_NAME" --query id --output tsv)
SCOPE_PATH="/subscriptions/$SUB_ID/resourceGroups/$RG_NAME"

echo "Assigning role '$ROLE_NAME' to group '$GROUP_NAME'..."

# 4. Map the assignment
az role assignment create \
  --assignee-object-id "$GROUP_OBJECT_ID" \
  --assignee-principal-type "Group" \
  --role "$ROLE_NAME" \
  --scope "$SCOPE_PATH"