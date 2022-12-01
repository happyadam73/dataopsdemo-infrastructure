//
// Project:           DataOps Demo
// Description:       KeyVault deployment script
// Author:            Adam Buckley
// Creation Date:	    05/11/2022
//
// Revision History:  1.0
//

@description('Location for key vault')
param location string = resourceGroup().location

@description('Specifies the tags that you want to apply to all resources.')
param tags object = {}

@description('Key Vault name')
param keyVaultName string

@description('Resource Group of existing log analytics workspace - set to empty string if none exist')
param existingLogWorkspaceResourceGroup string = ''

@description('Existing log analytics workspace name - set to empty string if none exist')
param existingLogWorkspaceName string = ''

// Main Key Vault deployment
resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    accessPolicies: []
    createMode: 'default'
    enabledForDeployment: true
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enablePurgeProtection: true
    enableRbacAuthorization: true
    enableSoftDelete: true  
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteRetentionInDays: 7
    tenantId: subscription().tenantId
  }
}

// Get existing Log Analytics Workspace if required
resource existingLogAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = if (length(existingLogWorkspaceName) > 0) {
  scope: resourceGroup(existingLogWorkspaceResourceGroup)
  name: existingLogWorkspaceName
}

// Assign diagnostic settings to log analytics if required
resource keyvaultDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (length(existingLogWorkspaceName) > 0) {
  scope: keyVault
  name: 'default'
  properties: {
    workspaceId: existingLogAnalyticsWorkspace.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]    
  }
}

// Outputs
output keyVaultId string = keyVault.id
