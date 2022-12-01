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

@description('Logical SQL Server name')
param sqlServerName string = uniqueString('sql', resourceGroup().id)

@description('Logical SQL Server Database name')
param sqlDatabaseName string

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

@secure()
param sqlAdminPassword string = '${toUpper(uniqueString(resourceGroup().id))}-${newGuid()}' 


// Variables

var sqlsvrVersion = '12.0'
var minimalTlsVersion = '1.2'
var dbSkuName = 'Basic'
var dbSkuTier = 'Basic'
var dbSkuFamily = ''
var dbSkuCapacity = 5
var dbCollation = 'SQL_Latin1_General_CP1_CI_AS'
var paasIpAllowAzure = '0.0.0.0'

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: 'CloudSA1396035b'
    administratorLoginPassword: sqlAdminPassword
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: sqlAADAdminPrincipalType
      login: sqlAADAdminPrincipalLogin
      sid: sqlAADAdminPrincipalSID
      tenantId: subscription().tenantId
    }
    version: sqlsvrVersion
    minimalTlsVersion: minimalTlsVersion
    publicNetworkAccess: 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
  }
}

resource sqlServerFirewallRuleAllowAzureServices 'Microsoft.Sql/servers/firewallRules@2020-11-01-preview' = {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: paasIpAllowAzure
    endIpAddress: paasIpAllowAzure
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  tags: tags
  sku: {
    name: dbSkuName
    tier: dbSkuTier
    family: dbSkuFamily
    capacity: dbSkuCapacity
  }
  properties: {
    catalogCollation: dbCollation
    collation: dbCollation
    createMode: 'Default'
    licenseType: 'LicenseIncluded'
    zoneRedundant: false
    requestedBackupStorageRedundancy: 'Local'
  }
}

