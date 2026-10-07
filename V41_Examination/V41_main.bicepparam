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
// No client secret: the app registration trusts the portal's managed identity.
// V41_setup_auth.sh creates the registration and prints the value to export:
//   export OIDC_CLIENT_ID='...'
param oidcClientId = readEnvironmentVariable('OIDC_CLIENT_ID', '')

// Shared mailbox that gets an e-mail for EVERY report. Urgent reports also go to the
// property manager. '' = no mail for ordinary reports. Example: 'felanmalan@nordvik.se'
param delatBrevladaMail = ''

// Extra recipients for urgent reports, e.g. 'jour@nordvik.example'
param akutMailExtra = ''

// Cost allocation tags
param avdelning = 'Fastighetsforvaltning'
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
// Region. If Azure reports a capacity shortage, try another one, e.g.
//   AZURE_LOCATION=northeurope ./V41_deploy.sh
param location = readEnvironmentVariable('AZURE_LOCATION', 'swedencentral')
// Notification job trigger: 'event' (default) or 'schedule' (every minute). Use 'schedule'
// if the job never starts by itself:  NOTIS_TRIGGER=schedule ./V41_deploy.sh app
param notisJobTrigger = readEnvironmentVariable('NOTIS_TRIGGER', 'event')

// --------------------------------------------------------------------------
// Optional - defaults live in V41_main.bicep. Uncomment to override.
// --------------------------------------------------------------------------
// param resourceGroupName = 'rg-nordvik-prod'
// param vnetName = 'vnet-nordvik-prod'
// param vnetAddressPrefix = '10.0.0.0/16'
// param subnetPePrefix = '10.0.2.0/24'
// param subnetAcaPrefix = '10.0.4.0/26'
// param storageAccountNamePrefix = 'stnordvik'
// param imagesContainerName = 'felanmalan'
// param docsContainerName = 'avtal'
