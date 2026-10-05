targetScope = 'subscription'

@description('Azure region for all resources')
param location string = 'swedencentral'

@allowed([
  'prod'
  'test'
  'demo'
])
@description('prod = production (zone redundant, 2 instances in office hours). test/demo = same layout, scales to zero, no zone redundancy, demo sign-in allowed.')
param environmentType string = 'prod'

@description('Name of the resource group')
param resourceGroupName string = 'rg-nordvik-${environmentType}'

@description('Object ID of the person/pipeline deploying (admin data access to the storage account). Leave empty to skip. az ad signed-in-user show --query id -o tsv')
param callerObjectId string = ''

@description('Object ID of the Entra group for property managers. Gets read/write on the contracts container. Leave empty to skip.')
param forvaltareGroupId string = ''

@description('Object ID of the Entra group for finance. Gets Cost Management Reader on the resource group (no data access). Leave empty to skip.')
param ekonomiGroupId string = ''

@description('Public IP allowed through the storage firewall. Leave empty to keep public network access to storage fully disabled.')
param allowedIpAddress string = ''

@description('Name of the virtual network')
param vnetName string = 'vnet-nordvik-${environmentType}'

@description('Address space of the virtual network')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Name of the subnet that holds the private endpoints')
param subnetPeName string = 'snet-pe'

@description('Address prefix of the private endpoint subnet')
param subnetPePrefix string = '10.0.2.0/24'

@description('Name of the subnet used by the Container Apps environment')
param subnetAcaName string = 'snet-aca'

@description('Address prefix of the Container Apps subnet (workload profiles environment needs at least /27)')
param subnetAcaPrefix string = '10.0.4.0/26'

@description('Prefix used to generate a globally unique storage account name (a random suffix is appended)')
param storageAccountNamePrefix string = 'stnordvik'

@description('SKU of the storage account. ZRS keeps data available if one zone fails.')
param storageAccountSku string = environmentType == 'prod' ? 'Standard_ZRS' : 'Standard_LRS'

@description('Blob container for fault-report photos')
param imagesContainerName string = 'felanmalan'

@description('Blob container for contracts and inspection protocols')
param docsContainerName string = 'avtal'

@description('Prefix used to generate a globally unique container registry name')
param acrNamePrefix string = 'acrnordvik'

@description('Name of the Container Apps environment')
param environmentName string = 'cae-nordvik-${environmentType}'

@description('Name of the container app (the portal)')
param appName string = 'ca-nordvik-portal-${environmentType}'

@description('Name of the notification job (reads the queue, calls Power Automate, sends urgent e-mail)')
param jobName string = 'caj-nordvik-notis-${environmentType}'

@description('Deploy the container app and job. Keep false on the first run (registry is still empty), true once the image is built.')
param deployApp bool = false

@description('Image name and tag inside the registry, e.g. portal:v1')
param imageName string = 'portal:v1'

@description('Optional Power Automate HTTP trigger URL that receives each ticket (creates the list item and notifies the manager). Leave empty to disable.')
@secure()
param flowUrl string = ''

@description('Demo sign-in with fake users instead of real authentication. Ignored (forced off) when environmentType is prod.')
param demoMode bool = false

@description('Client ID of the Entra app registration. Created by V41_setup_auth.sh. Leave empty until it exists (the portal is then locked, not open). There is no client secret: the app registration trusts the managed identity.')
param oidcClientId string = ''

@description('Extra recipients (comma separated) for urgent reports, besides the property manager')
param akutMailExtra string = ''

// ---- Cost allocation tags (applied to the resource group and every resource) ----
@description('Tag avdelning: which department pays for the platform')
param avdelning string = 'Fastighetsforvaltning'

@description('Tag fastighet: property the resources belong to. The portal is shared by all properties, so the default is gemensam.')
param fastighet string = 'gemensam'

@description('Tag kostnadsstalle')
param kostnadsstalle string = 'ej-angivet'

@description('Tag agare: who owns the environment')
param agare string = 'ej-angivet'

@description('Monthly budget for the resource group, in the currency of the Azure invoice')
param budgetAmount int = 2500

@description('Who gets budget alerts (80 % of actual cost, 100 % of forecast). Leave empty to skip the budget.')
param budgetContactEmails array = []

@description('First day of a month. If a redeploy later complains about the budget start date, pin this to a fixed value.')
param budgetStartDate string = utcNow('yyyy-MM-01')

var tags = {
  foretag: 'Nordvik'
  applikation: 'hyresgastportal'
  miljo: environmentType
  avdelning: avdelning
  fastighet: fastighet
  kostnadsstalle: kostnadsstalle
  agare: agare
}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module nordvik 'V41_resources.bicep' = {
  name: 'nordvik-resources'
  scope: rg
  params: {
    location: location
    tags: tags
    environmentType: environmentType
    callerObjectId: callerObjectId
    forvaltareGroupId: forvaltareGroupId
    ekonomiGroupId: ekonomiGroupId
    allowedIpAddress: allowedIpAddress
    vnetName: vnetName
    vnetAddressPrefix: vnetAddressPrefix
    subnetPeName: subnetPeName
    subnetPePrefix: subnetPePrefix
    subnetAcaName: subnetAcaName
    subnetAcaPrefix: subnetAcaPrefix
    storageAccountNamePrefix: storageAccountNamePrefix
    storageAccountSku: storageAccountSku
    imagesContainerName: imagesContainerName
    docsContainerName: docsContainerName
    acrNamePrefix: acrNamePrefix
    environmentName: environmentName
    appName: appName
    jobName: jobName
    deployApp: deployApp
    imageName: imageName
    flowUrl: flowUrl
    demoMode: demoMode && environmentType != 'prod'
    oidcClientId: oidcClientId
    akutMailExtra: akutMailExtra
    budgetAmount: budgetAmount
    budgetContactEmails: budgetContactEmails
    budgetStartDate: budgetStartDate
  }
}

output storageAccountName string = nordvik.outputs.storageAccountName
output acrName string = nordvik.outputs.acrName
output appUrl string = nordvik.outputs.appUrl
output oidcRedirectUri string = nordvik.outputs.oidcRedirectUri
output environmentDefaultDomain string = nordvik.outputs.environmentDefaultDomain
output mailSender string = nordvik.outputs.mailSender
