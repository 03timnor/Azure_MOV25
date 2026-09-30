targetScope = 'subscription'

@description('Azure region for all resources')
param location string = 'swedencentral'

@description('Name of the resource group')
param resourceGroupName string = 'rg-novatrix'

@description('Object ID of the Azure AD identity that should get Storage Blob Data Contributor on the storage account (az ad signed-in-user show --query id -o tsv)')
param callerObjectId string

@description('Your public IP address, allowed through the storage account firewall. Leave empty to skip.')
param allowedIpAddress string = ''

@description('Name of the virtual network')
param vnetName string = 'vnet-novatrix'

@description('Address space of the virtual network')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Name of the subnet that holds the storage private endpoint')
param subnetDbName string = 'snet-db'

@description('Address prefix of the private endpoint subnet')
param subnetDbPrefix string = '10.0.2.0/24'

@description('Name of the subnet used by the Container Apps environment')
param subnetAcaName string = 'snet-aca'

@description('Address prefix of the Container Apps subnet (workload profiles environment needs at least /27)')
param subnetAcaPrefix string = '10.0.4.0/26'

@description('Prefix used to generate a globally unique storage account name (a random suffix is appended)')
param storageAccountNamePrefix string = 'stnovatrix'

@description('SKU of the storage account')
param storageAccountSku string = 'Standard_LRS'

@description('Name of the blob container used for support tickets')
param containerName string = 'arenden'

@description('Prefix used to generate a globally unique container registry name')
param acrNamePrefix string = 'acrnovatrix'

@description('Name of the Container Apps environment')
param environmentName string = 'cae-novatrix'

@description('Name of the container app')
param appName string = 'ca-novatrix-arendeapp'

@description('Deploy the container app itself. Keep false on the first run (registry is still empty), true once the image is built.')
param deployApp bool = false

@description('Image name and tag inside the registry, e.g. arendeapp:v1')
param imageName string = 'arendeapp:v1'

@description('Optional Power Automate HTTP trigger URL that receives each ticket. Leave empty to disable.')
@secure()
param flowUrl string = ''

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
}

module novatrix 'V40_resources.bicep' = {
  name: 'novatrix-resources'
  scope: rg
  params: {
    location: location
    callerObjectId: callerObjectId
    allowedIpAddress: allowedIpAddress
    vnetName: vnetName
    vnetAddressPrefix: vnetAddressPrefix
    subnetDbName: subnetDbName
    subnetDbPrefix: subnetDbPrefix
    subnetAcaName: subnetAcaName
    subnetAcaPrefix: subnetAcaPrefix
    storageAccountNamePrefix: storageAccountNamePrefix
    storageAccountSku: storageAccountSku
    containerName: containerName
    acrNamePrefix: acrNamePrefix
    environmentName: environmentName
    appName: appName
    deployApp: deployApp
    imageName: imageName
    flowUrl: flowUrl
  }
}

output storageAccountName string = novatrix.outputs.storageAccountName
output acrName string = novatrix.outputs.acrName
output appUrl string = novatrix.outputs.appUrl
