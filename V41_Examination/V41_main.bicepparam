using 'V41_main.bicep'

// --------------------------------------------------------------------------
// Required - replace the two 'placeholder' values with your own (or '' to skip).
// --------------------------------------------------------------------------

// Object ID of the person/pipeline that deploys (admin access to the storage account):
//   az ad signed-in-user show --query id -o tsv
// Use '' to skip.
param callerObjectId = 'placeholder'

// Public IP allowed through the storage firewall (curl -s https://ifconfig.me).
// Use '' to keep public network access to the storage account disabled (recommended
// once you no longer need to browse the data from your own machine).
param allowedIpAddress = 'placeholder'

// Power Automate HTTP trigger URL. It contains a signature, so it is read from the
// environment and never written into this file:
//   export FLOW_URL='https://...'
// Not set = the flow is not called.
param flowUrl = readEnvironmentVariable('FLOW_URL', '')

// --------------------------------------------------------------------------
// Roles, sign-in and cost (fill in when available; '' / [] skips the feature).
// --------------------------------------------------------------------------

// Entra groups. Managers get read/write on contracts and protocols; finance gets
// Cost Management Reader only (no access to personal data).
param forvaltareGroupId = ''
param ekonomiGroupId = ''

// Sign-in against your own Entra ID tenant (same accounts and UPNs for tenants and staff).
// V41_setup_auth.sh creates the app registration and prints these two values:
//   export OIDC_CLIENT_ID='...'
//   export OIDC_CLIENT_SECRET='...'
// oidcWellKnownUrl stays '' = your own tenant. Set it only for another provider.
param oidcClientId = readEnvironmentVariable('OIDC_CLIENT_ID', '')
param oidcWellKnownUrl = ''
param oidcClientSecret = readEnvironmentVariable('OIDC_CLIENT_SECRET', '')

// Extra recipients for urgent reports, e.g. 'jour@nordvik.example'
param akutMailExtra = ''

// Cost allocation tags
param avdelning = 'Fastighetsforvaltning'
param fastighet = 'gemensam'
param kostnadsstalle = 'ej-angivet'
param agare = 'ej-angivet'

// Budget alerts for the resource group (about 2 500 kr / month).
param budgetAmount = 2500
param budgetContactEmails = []

// --------------------------------------------------------------------------
// Controlled by V41_deploy.sh through environment variables - do not edit.
// A second environment (test / demo) is the same files with other values:
//   ENVIRONMENT_TYPE=demo DEMO_MODE=true ./V41_deploy.sh
// --------------------------------------------------------------------------
param environmentType = readEnvironmentVariable('ENVIRONMENT_TYPE', 'prod')
param demoMode = readEnvironmentVariable('DEMO_MODE', 'false') == 'true'
param deployApp = readEnvironmentVariable('DEPLOY_APP', 'false') == 'true'
param imageName = readEnvironmentVariable('IMAGE_NAME', 'portal:v1')

// --------------------------------------------------------------------------
// Optional - defaults live in V41_main.bicep. Uncomment to override.
// --------------------------------------------------------------------------
// param location = 'swedencentral'
// param resourceGroupName = 'rg-nordvik-prod'
// param vnetName = 'vnet-nordvik-prod'
// param vnetAddressPrefix = '10.0.0.0/16'
// param subnetPePrefix = '10.0.2.0/24'
// param subnetAcaPrefix = '10.0.4.0/26'
// param storageAccountNamePrefix = 'stnordvik'
// param imagesContainerName = 'felanmalan'
// param docsContainerName = 'avtal'
