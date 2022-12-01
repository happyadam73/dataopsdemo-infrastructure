//
// Project:           DataOps Demo
// Description:       KeyVault deployment script
// Author:            Adam Buckley
// Creation Date:	    05/11/2022
//
// Revision History:  1.0
//

targetScope = 'resourceGroup'

// Parameters
@description('Storage account name')
param storageAccountName string = uniqueString(resourceGroup().id)

@description('Storage account location')
param location string = resourceGroup().location

@description('Storage account sku')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param storageSku string = 'Standard_LRS'

@description('Storage account kind')
@allowed([
  'Storage'
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
param storageKind string = 'StorageV2'

@description('Storage account access tier, Hot for frequently accessed data or Cool for infreqently accessed data')
@allowed([
  'Hot'
  'Cool'
])
param storageTier string = 'Hot'

@description('Enable blob service encryption')
param enableBlobServiceEncryption bool = true

@description('Enable file service encryption')
param enableFileServiceEncryption bool = true

@description('Enable queue service encryption')
param enableQueueServiceEncryption bool = true

@description('Enable table service encryption')
param enableTableServiceEncryption bool = true

@description('Enable hierarchical namespace (data lake service)')
param enableHierarchicalNamespace bool = true

@description('NFS 3.0 protocol support enabled if set to true.')
param enableNFSV3 bool = false

@description('Allow large file shares if sets to Enabled. It cannot be disabled once it is enabled.')
param largeFileSharesState string = 'Disabled'

@description('Set the minimum TLS version to be permitted on requests to storage. The default interpretation is TLS 1.0 for this property.')
param minimumTlsVersion string = 'TLS1_2'

@description('Allows https traffic only to storage service if sets to true.')
param supportsHttpsTrafficOnly bool = true

@description('Enable lifecycle management policy')
param enableLifecycleManagementPolicy bool = true

@description('If lifecycle management policy enabled, then number of days before tier is moved from Hot to Cool')
param tierToCoolNumDays int = 90

@description('Enable container delete retention policy')
param enableContainerDeleteRetentionPolicy bool = true

@description('Number of day retention if container delete policy enabled')
param containerDeleteRetentionPolicyNumDays int = 7

@description('Array of container names to create within the storage account')
param containerNames array

@description('Resource Group of existing log analytics workspace - set to empty string if none exist')
param existingLogWorkspaceResourceGroup string = ''

@description('Existing log analytics workspace name - set to empty string if none exist')
param existingLogWorkspaceName string = ''

@description('If specified then still stored the Account key and Connection as secrets in the keyvault - set to empty string if none exist')
param keyVaultName string = ''

@description('Specifies the tags that you want to apply to all resources.')
param tags object = {}

var storageAccountKeySecretName = '${storageAccountName}-key'
var storageAccountConnectionStringSecretName = '${storageAccountName}-connection-string'


// Create main storage account
resource storage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageAccountName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: storageSku
  }
  kind: storageKind
  properties: {
    accessTier: storageTier
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: false
      services: {
        blob: {
          enabled: enableBlobServiceEncryption
        }
        file: {
          enabled: enableFileServiceEncryption
        }
        queue: {
          enabled: enableQueueServiceEncryption
        }
        table: {
          enabled: enableTableServiceEncryption
        }
      }
    }
    isHnsEnabled: enableHierarchicalNamespace
    isNfsV3Enabled: enableNFSV3
    largeFileSharesState: largeFileSharesState
    minimumTlsVersion: minimumTlsVersion
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
  }
}

// assign management policies
resource storageManagementPolicies 'Microsoft.Storage/storageAccounts/managementPolicies@2021-02-01' = {
  parent: storage
  name: 'default'
  properties: {
    policy: {
      rules: [
        {
          enabled: enableLifecycleManagementPolicy
          name: 'default'
          type: 'Lifecycle'
          definition: {
            actions: {
              baseBlob: {
                tierToCool: {
                  daysAfterModificationGreaterThan: tierToCoolNumDays
                }
              }
              snapshot: {
                tierToCool: {
                  daysAfterCreationGreaterThan: tierToCoolNumDays
                }
              }
              version: {
                tierToCool: {
                  daysAfterCreationGreaterThan: tierToCoolNumDays
                }
              }
            }
            filters: {
              blobTypes: [
                'blockBlob'
              ]
              prefixMatch: []
            }
          }
        }
      ]
    }
  }
}

// assign container delete retention policy
resource storageBlobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-02-01' = {
  parent: storage
  name: 'default'
  properties: {
    containerDeleteRetentionPolicy: {
      enabled: enableContainerDeleteRetentionPolicy
      days: containerDeleteRetentionPolicyNumDays
    }
    cors: {
      corsRules: []
    }
  }
}

// add containers to the storage account
resource storageFileSystems 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = [for containerName in containerNames: {
  parent: storageBlobServices
  name: containerName
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}]

// Get existing Log Analytics Workspace if required
resource existingLogAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = if (length(existingLogWorkspaceName) > 0) {
  scope: resourceGroup(existingLogWorkspaceResourceGroup)
  name: existingLogWorkspaceName
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-01-01' existing = {
  name: 'default'
  parent: storage
}

// Assign diagnostic settings to log analytics if required
resource storageDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (length(existingLogWorkspaceName) > 0) {
  dependsOn: [
    blobService
  ]
  scope: blobService
  name: 'blobdiagnostics'
  properties: {
    workspaceId: existingLogAnalyticsWorkspace.id
    logs: [
      {
        category: 'StorageRead'
        enabled: true
      }
      {
        category: 'StorageWrite'
        enabled: true
      }
      {
        category: 'StorageDelete'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]    
  }
}


// Get reference to KV
resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = if (length(keyVaultName) > 0) {
  name: keyVaultName
}

// Store the connection string in KV if specified
resource storageAccountConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = if (length(keyVaultName) > 0) {
  name: '${keyVault.name}/${storageAccountConnectionStringSecretName}'
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${listKeys(storage.id, storage.apiVersion).keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
  }
}

// Store the account key in KV if specified
resource storageAccountKeySecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = if (length(keyVaultName) > 0) {
  name: '${keyVault.name}/${storageAccountKeySecretName}'
  properties: {
    value: '${listKeys(storage.id, storage.apiVersion).keys[0].value}'
  }
}

// Outputs
output storageId string = storage.id
output storageFileSystemIds array = [for containerName in containerNames: {
  storageFileSystemId: resourceId('Microsoft.Storage/storageAccounts/blobServices/containers', storageAccountName, 'default', containerName)
}]
