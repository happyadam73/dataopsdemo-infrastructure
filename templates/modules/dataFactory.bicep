//
// Project:           DataOps Demo
// Description:       KeyVault deployment script
// Author:            Adam Buckley
// Creation Date:	    05/11/2022
//
// Revision History:  1.0
//

@description('Location for data factory')
param location string = resourceGroup().location

@description('Data Factory name')
param dataFactoryName string

param environment string = 'dev'

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

var _repositoryType = (repositoryType == 'AzureDevOps') ? 'FactoryVSTSConfiguration' : 'FactoryGitHubConfiguration'

var azDevopsRepoConfiguration = {
  accountName: accountName
  repositoryName: repositoryName
  collaborationBranch: collaborationBranch
  rootFolder: rootFolder  
  type: _repositoryType
  projectName: projectName
}

var gitHubRepoConfiguration = {
  accountName: accountName
  repositoryName: repositoryName
  collaborationBranch: collaborationBranch
  rootFolder: rootFolder  
  type: _repositoryType
}


resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' =  {
  name: dataFactoryName
  location: location
  identity: {
    type: 'SystemAssigned'
  }  
  properties: {
    repoConfiguration: (environment == 'dev') ? (repositoryType == 'AzureDevOps') ? azDevopsRepoConfiguration : gitHubRepoConfiguration : {}
  }
}

// Outputs
output dataFactoryId string = dataFactory.id
output dataFactoryPrincipalId string = dataFactory.identity.principalId
