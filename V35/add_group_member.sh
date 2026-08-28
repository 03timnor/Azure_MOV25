# 1. Define group and array of user emails
GROUP_NAME="placeholder"
USER_EMAILS=("placeholder")

# 2. Get Group ID
GROUP_ID=$(az ad group show --group "$GROUP_NAME" --query id --output tsv)

# 3. Loop through and add each user
for email in "${USER_EMAILS[@]}"; do
    echo "Processing $email..."
    
    # Get the user's Object ID based on the email address
    USER_ID=$(az ad user show --id "$email" --query id --output tsv 2>/dev/null)
    
    if [ -n "$USER_ID" ]; then
        echo "Adding user ID $USER_ID to group..."
        az ad group member add --group "$GROUP_ID" --member-id "$USER_ID"
    else
        echo "Error: Could not find user with email $email"
    fi
done

echo "All users successfully processed!"