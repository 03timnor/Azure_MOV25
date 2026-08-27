# 1. Define your group properties
GROUP_DISPLAY_NAME="placeholder"
GROUP_MAIL_NICKNAME="placeholder"

echo "Creating security group '$GROUP_DISPLAY_NAME' with mail nickname '$GROUP_MAIL_NICKNAME'..."

# 2. Create the security group
az ad group create \
  --display-name "$GROUP_DISPLAY_NAME" \
  --mail-nickname "$GROUP_MAIL_NICKNAME"