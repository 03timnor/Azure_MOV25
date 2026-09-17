@description('Azure region for all resources')
param location string

@description('Admin username for the VM')
param vmAdminUsername string

@secure()
@description('SSH public key to add to the VM for the admin user')
param sshPublicKey string

@description('Object ID of the identity that should get data-plane access to the storage account')
param callerObjectId string

@description('Public IP address allowed through the storage account firewall')
param allowedIpAddress string = ''

@description('Size of the web server VM')
param vmSize string

@description('Name of the virtual machine')
param vmName string

@description('SKU of the OS image used for the VM')
param vmImageSku string

@description('Name of the virtual network')
param vnetName string

@description('Address space of the virtual network')
param vnetAddressPrefix string

@description('Name of the web subnet')
param subnetWebName string

@description('Address prefix of the web subnet')
param subnetWebPrefix string

@description('Name of the database subnet')
param subnetDbName string

@description('Address prefix of the database subnet')
param subnetDbPrefix string

@description('Address prefix of the AzureBastionSubnet')
param subnetBastionPrefix string

@description('Name of the network security group protecting the web subnet')
param nsgWebName string

@description('TCP port allowed inbound for HTTP')
param httpPort int

@description('TCP port allowed inbound for HTTPS')
param httpsPort int

@description('Name of the Azure Bastion host')
param bastionName string

@description('SKU of the Azure Bastion host')
param bastionSkuName string

@description('Name of the Bastion public IP address')
param bastionPipName string

@description('Prefix used to generate a globally unique storage account name')
param storageAccountNamePrefix string

@description('SKU of the storage account')
param storageAccountSku string

@description('Name of the blob container used for support tickets')
param containerName string

// Fixed subnet name required by Azure Bastion; cannot be renamed.
var subnetBastionName = 'AzureBastionSubnet'

// Globally unique storage account name derived from the resource group.
var storageAccountName = toLower('${storageAccountNamePrefix}${uniqueString(resourceGroup().id)}')

// Placeholder text expected inside cloud-init.yaml, replaced with the real
// generated storage account name before it's passed to the VM.
var cloudInitPlaceholder = '${storageAccountNamePrefix}XXXX'

// Built-in role definition ID for "Storage Blob Data Contributor".
var storageBlobDataContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')

// --------------------------------------------------------------------------
// Networking
// --------------------------------------------------------------------------
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressPrefix]
    }
  }
}

resource nsgWeb 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nsgWebName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTP'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: string(httpPort)
        }
      }
      {
        name: 'Allow-HTTPS'
        properties: {
          priority: 150
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: string(httpsPort)
        }
      }
    ]
  }
}

resource subnetWeb 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  parent: vnet
  name: subnetWebName
  properties: {
    addressPrefix: subnetWebPrefix
    networkSecurityGroup: { id: nsgWeb.id }
  }
}

resource subnetDb 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  parent: vnet
  name: subnetDbName
  properties: {
    addressPrefix: subnetDbPrefix
    privateEndpointNetworkPolicies: 'Disabled'
  }
  dependsOn: [subnetWeb]
}

resource subnetBastion 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  parent: vnet
  name: subnetBastionName
  properties: {
    addressPrefix: subnetBastionPrefix
  }
  dependsOn: [subnetDb]
}

// --------------------------------------------------------------------------
// Storage account + private endpoint
// --------------------------------------------------------------------------
resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: { name: storageAccountSku }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Deny'
      ipRules: empty(allowedIpAddress) ? [] : [
        {
          value: allowedIpAddress
          action: 'Allow'
        }
      ]
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storage
  name: 'default'
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: containerName
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
}

resource dnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsZone
  name: 'link-${vnetName}'
  location: 'global'
  properties: {
    virtualNetwork: { id: vnet.id }
    registrationEnabled: false
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: 'pe-${storageAccountName}-blob'
  location: location
  properties: {
    subnet: { id: subnetDb.id }
    privateLinkServiceConnections: [
      {
        name: 'conn-pe-${storageAccountName}-blob'
        properties: {
          privateLinkServiceId: storage.id
          groupIds: ['blob']
        }
      }
    ]
  }
}

resource peDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'blob'
        properties: { privateDnsZoneId: privateDnsZone.id }
      }
    ]
  }
}

// --------------------------------------------------------------------------
// Bastion
// --------------------------------------------------------------------------
resource bastionPip 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: bastionPipName
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-11-01' = {
  name: bastionName
  location: location
  sku: { name: bastionSkuName }
  properties: {
    enableTunneling: true
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: { id: subnetBastion.id }
          publicIPAddress: { id: bastionPip.id }
        }
      }
    ]
  }
}

// --------------------------------------------------------------------------
// Web server VM
// --------------------------------------------------------------------------
resource vmPip 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'pip-${vmName}'
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: 'nic-${vmName}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: subnetWeb.id }
          publicIPAddress: { id: vmPip.id }
        }
      }
    ]
  }
}

// Requires cloud-init.yaml to be present next to this file. The placeholder
// text inside it (storageAccountNamePrefix + "XXXX") is replaced with the
// actual generated storage account name before being passed to the VM.
var cloudInitContent = replace(loadTextContent('cloud-init.yaml'), cloudInitPlaceholder, storageAccountName)

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: { vmSize: vmSize }
    osProfile: {
      computerName: vmName
      adminUsername: vmAdminUsername
      customData: base64(cloudInitContent)
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${vmAdminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: vmImageSku
        version: 'latest'
      }
      osDisk: { createOption: 'FromImage' }
    }
    networkProfile: {
      networkInterfaces: [
        { id: nic.id }
      ]
    }
  }
}

// --------------------------------------------------------------------------
// Role assignments
// --------------------------------------------------------------------------
resource callerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storage.id, callerObjectId, storageBlobDataContributorRoleId)
  scope: storage
  properties: {
    roleDefinitionId: storageBlobDataContributorRoleId
    principalId: callerObjectId
    principalType: 'User'
  }
}

resource vmRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(container.id, vm.id, storageBlobDataContributorRoleId)
  scope: container
  properties: {
    roleDefinitionId: storageBlobDataContributorRoleId
    principalId: vm.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output vmPublicIp string = vmPip.properties.ipAddress
output storageAccountName string = storageAccountName
