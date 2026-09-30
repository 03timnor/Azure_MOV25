using 'V40_main.bicep'

// --------------------------------------------------------------------------
// Required - replace the placeholders with your own values.
// --------------------------------------------------------------------------

// Object ID of the identity that should get Storage Blob Data Contributor:
//   az ad signed-in-user show --query id -o tsv
param callerObjectId = 'placeholder'

// Your public IP, allowed through the storage firewall (curl -s https://ifconfig.me).
// Use '' to skip.
param allowedIpAddress = 'placeholder'

// Power Automate HTTP trigger URL. Use '' to disable the flow call.
param flowUrl = 'placeholder'

// --------------------------------------------------------------------------
// Controlled by V40_deploy.sh through environment variables - do not edit.
// --------------------------------------------------------------------------
param deployApp = readEnvironmentVariable('DEPLOY_APP', 'false') == 'true'
param imageName = readEnvironmentVariable('IMAGE_NAME', 'arendeapp:v1')

// --------------------------------------------------------------------------
// Optional - defaults live in V40_main.bicep. Uncomment to override.
// --------------------------------------------------------------------------
// param location = 'swedencentral'
// param resourceGroupName = 'rg-novatrix'
// param vnetName = 'vnet-novatrix'
// param vnetAddressPrefix = '10.0.0.0/16'
// param subnetDbPrefix = '10.0.2.0/24'
// param subnetAcaPrefix = '10.0.4.0/26'
// param storageAccountNamePrefix = 'stnovatrix'
// param containerName = 'arenden'
