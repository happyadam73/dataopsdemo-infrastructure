//
// Project:           DataOps Demo
// Description:       Main deployment script for all Azure  resources including:
//                    KeyVault, DataLake, DataFactory, Azure SQL
// Author:            Adam Buckley
// Creation Date:	    05/11/2022
//
// Revision History:  1.0
//

// Parameters
@description('Location for all resources.')
param location string = resourceGroup().location

@description('Abbreviated Location Code')
param locationCode string

@description('Abbreviated Environment Code')
@allowed([
  'dev'
  'pre'
  'prd'
])
param environment string = 'dev'

@description('Project Abbreviation')
param project string = 'awbcicddemo'

@description('Resource Sequence ID')
param resourceSequenceId int = 1

@description('Resource Group of existing log analytics workspace - set to empty string if none exist')
param existingLogWorkspaceResourceGroup string = ''

@description('Existing log analytics workspace name - set to empty string if none exist')
param existingLogWorkspaceName string = ''

@description('Specifies the tags that you want to apply to all resources.')
param tags object = {}

@description('SQL Admin AAD Principal Type')
@allowed([
  'Application'
  'Group'
  'User'
])
param sqlAADAdminPrincipalType string = 'User'

@description('SQL Admin AAD Principal login name')
param sqlAADAdminPrincipalLogin string

@description('SQL Admin AAD Principal SID')
param sqlAADAdminPrincipalSID string

@allowed([
  'AzureDevOps'
  'GitHub'
  ''
])
param repositoryType string = 'AzureDevOps'
param projectName string  = ''
param repositoryName string = ''
param accountName string = ''
param collaborationBranch string = 'main'
param rootFolder string = '/'

// derive resource names
var keyVaultName = 'kv${project}${environment}${locationCode}${resourceSequenceId}'
var storageAccountName = 'adls${project}${environment}${locationCode}${resourceSequenceId}'
var dataFactoryName = 'adf-${project}-${environment}-${locationCode}-${resourceSequenceId}'
var sqlServerName = 'sqlsvr-${project}-${environment}-${locationCode}-${resourceSequenceId}'
var sqlDatabaseName = 'sqldb-${project}-${environment}-${locationCode}-${resourceSequenceId}'

// Contain names for the storage accounts
var containerNames = [
  'raw'
  'enriched'
  'curated'
  'data'
  'workspace'
  'bronze'
  'silver'
  'gold'
  'staging'
]

// Resources

// Create Key Vault
module keyVault 'modules/keyvault.bicep' = {
  name: 'keyVault'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    keyVaultName: keyVaultName
    existingLogWorkspaceResourceGroup: existingLogWorkspaceResourceGroup
    existingLogWorkspaceName: existingLogWorkspaceName
  }
}

// Create the storage account
module storageAccount 'modules/storageAccount.bicep' = {
  name: 'storageAccount'
  scope: resourceGroup()
  params: {
    location: location
    storageAccountName: storageAccountName
    keyVaultName: keyVaultName
    existingLogWorkspaceResourceGroup: existingLogWorkspaceResourceGroup
    existingLogWorkspaceName: existingLogWorkspaceName
    containerNames: containerNames
    tags: tags
  }
  dependsOn: [
    keyVault
  ]
}

// Create Data Factory
module dataFactory 'modules/dataFactory.bicep' = {
  name: 'dataFactory'
  scope: resourceGroup()
  params: {
    location: location
    dataFactoryName: dataFactoryName
    environment: environment
    repositoryType: repositoryType
    accountName: accountName
    repositoryName: repositoryName
    collaborationBranch: collaborationBranch
    rootFolder: rootFolder  
    projectName: projectName
  }

}

// Create Azure SQL Server and Database
module sqlDatabase 'modules/sqlDatabase.bicep' = {
  name: 'sqlDatabase'
  scope: resourceGroup()
  params: {
    location: location
    sqlServerName: sqlServerName
    sqlDatabaseName: sqlDatabaseName
    sqlAADAdminPrincipalType: sqlAADAdminPrincipalType
    sqlAADAdminPrincipalLogin: sqlAADAdminPrincipalLogin
    sqlAADAdminPrincipalSID: sqlAADAdminPrincipalSID
  }
}

// Assign Data Factory Managed Identity key vaults user role to the key vault
module assignDataFactoryKeyVaultPermissions 'modules/dataFactoryRoleAssignmentKeyVault.bicep' = {
  name: 'assignDataFactoryKeyVaultPermissions'
  params: {
    keyVaultName: keyVaultName
    dataFactoryName: dataFactoryName
  }
  dependsOn: [
    keyVault
    dataFactory
  ]
}
