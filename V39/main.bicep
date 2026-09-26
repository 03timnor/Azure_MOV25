targetScope = 'subscription'

@description('Azure region for all resources')
param location string = 'swedencentral'

@description('Name of the resource group')
param resourceGroupName string = 'rg-novatrix'

@description('Admin username for the VM')
param vmAdminUsername string = 'azureuser'

@description('SSH public key to add to the VM for the admin user')
@secure()
param sshPublicKey string

@description('Object ID of the Azure AD identity that should get Storage Blob Data Contributor on the storage account (e.g. the output of "az ad signed-in-user show --query id -o tsv")')
param callerObjectId string

@description('Your public IP address, allowed through the storage account firewall. Leave empty to skip.')
param allowedIpAddress string = ''

@description('Size of the web server VM')
param vmSize string = 'Standard_B2ats_v2'

@description('Name of the virtual machine')
param vmName string = 'VM-Novatrix-Web'

@description('SKU of the OS image used for the VM')
param vmImageSku string = '22_04-lts-gen2'

@description('Name of the virtual network')
param vnetName string = 'vnet-novatrix'

@description('Address space of the virtual network')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Name of the web subnet')
param subnetWebName string = 'snet-web'

@description('Address prefix of the web subnet')
param subnetWebPrefix string = '10.0.1.0/24'

@description('Name of the database subnet')
param subnetDbName string = 'snet-db'

@description('Address prefix of the database subnet')
param subnetDbPrefix string = '10.0.2.0/24'

@description('Address prefix of the AzureBastionSubnet (the subnet name itself is fixed by Azure and cannot be changed)')
param subnetBastionPrefix string = '10.0.3.0/26'

@description('Name of the network security group protecting the web subnet')
param nsgWebName string = 'nsg-web'

@description('TCP port allowed inbound for HTTP')
param httpPort int = 80

@description('TCP port allowed inbound for HTTPS')
param httpsPort int = 443

@description('Name of the Azure Bastion host')
param bastionName string = 'bastion-novatrix'

@description('SKU of the Azure Bastion host')
param bastionSkuName string = 'Standard'

@description('Name of the Bastion public IP address')
param bastionPipName string = 'pip-bastion-novatrix'

@description('Prefix used to generate a globally unique storage account name (a random suffix is appended)')
param storageAccountNamePrefix string = 'stnovatrix'

@description('SKU of the storage account')
param storageAccountSku string = 'Standard_LRS'

@description('Name of the blob container used for support tickets')
param containerName string = 'arenden'

@description('Optional Power Automate HTTP trigger URL that receives each ticket. Leave empty to disable.')
param flowUrl string = ''

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
}

module novatrix 'resources.bicep' = {
  name: 'novatrix-resources'
  scope: rg
  params: {
    location: location
    vmAdminUsername: vmAdminUsername
    sshPublicKey: sshPublicKey
    callerObjectId: callerObjectId
    allowedIpAddress: allowedIpAddress
    vmSize: vmSize
    vmName: vmName
    vmImageSku: vmImageSku
    vnetName: vnetName
    vnetAddressPrefix: vnetAddressPrefix
    subnetWebName: subnetWebName
    subnetWebPrefix: subnetWebPrefix
    subnetDbName: subnetDbName
    subnetDbPrefix: subnetDbPrefix
    subnetBastionPrefix: subnetBastionPrefix
    nsgWebName: nsgWebName
    httpPort: httpPort
    httpsPort: httpsPort
    bastionName: bastionName
    bastionSkuName: bastionSkuName
    bastionPipName: bastionPipName
    storageAccountNamePrefix: storageAccountNamePrefix
    storageAccountSku: storageAccountSku
    containerName: containerName
    flowUrl: flowUrl
  }
}

output vmPublicIp string = novatrix.outputs.vmPublicIp
output storageAccountName string = novatrix.outputs.storageAccountName
output bastionConnectCommand string = novatrix.outputs.bastionConnectCommand
