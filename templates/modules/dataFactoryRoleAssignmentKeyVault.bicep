//
// Project:           DataOps Demo
// Description:       Grant Data Factory Secret User access to key vault
// Author:            Adam Buckley
// Creation Date:	    05/11/2022
//
// Revision History:  1.0
//

// Parameters
@description('Data Factory Name')
param dataFactoryName string

@description('Key Vault Name')
param keyVaultName string

// Resources
// Get existing key vault
resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVaultName
}

// Get existing data factory
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: dataFactoryName
}

// Assign key vault secrets user to the data factory
resource dataFactoryRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(uniqueString(keyVault.id, dataFactory.id))
  scope: keyVault
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: dataFactory.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
