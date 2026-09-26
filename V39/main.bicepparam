using 'main.bicep'

// --------------------------------------------------------------------------
// Required — these have no default value in main.bicep and must be set here
// (or passed via --parameters at deploy time).
// --------------------------------------------------------------------------

// Your SSH public key, e.g. the contents of ~/.ssh/id_rsa.pub
param sshPublicKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... your-key-here'

// Object ID of the identity that should get Storage Blob Data Contributor
// on the storage account, e.g.:
//   az ad signed-in-user show --query id -o tsv
param callerObjectId = '00000000-0000-0000-0000-000000000000'

// Your public IP address, allowed through the storage account firewall.
// Find it with: curl -s https://ifconfig.me
param allowedIpAddress = '203.0.113.10'

// --------------------------------------------------------------------------
// Optional — everything below already has a default in main.bicep.
// Uncomment and change only the values you want to override for this
// environment; leave the rest to fall back to the defaults.
// --------------------------------------------------------------------------

// param location = 'swedencentral'
// param resourceGroupName = 'rg-novatrix'
// param vmAdminUsername = 'azureuser'
// param vmSize = 'Standard_B2ats_v2'
// param vmName = 'VM-Novatrix-Web'
// param vmImageSku = '22_04-lts-gen2'
// param vnetName = 'vnet-novatrix'
// param vnetAddressPrefix = '10.0.0.0/16'
// param subnetWebName = 'snet-web'
// param subnetWebPrefix = '10.0.1.0/24'
// param subnetDbName = 'snet-db'
// param subnetDbPrefix = '10.0.2.0/24'
// param subnetBastionPrefix = '10.0.3.0/26'
// param nsgWebName = 'nsg-web'
// param httpPort = 80
// param httpsPort = 443
// param bastionName = 'bastion-novatrix'
// param bastionSkuName = 'Standard'
// param bastionPipName = 'pip-bastion-novatrix'
// param storageAccountNamePrefix = 'stnovatrix'
// param storageAccountSku = 'Standard_LRS'
// param containerName = 'arenden'
// param flowUrl = 'https://prod-00.northeurope.logic.azure.com/workflows/...'
