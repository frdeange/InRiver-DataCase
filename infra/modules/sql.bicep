// ============================================================
// Azure SQL Logical Server + 3 Tenant Databases
// Uses Azure AD-only authentication (no SQL admin password)
// as required by MCAPS governance policies.
// ============================================================

@description('Azure region')
param location string

@description('Resource name prefix')
param resourcePrefix string

@description('Object ID of the Entra ID user/group to set as SQL AD admin')
param entraAdminObjectId string

@description('Display name of the Entra ID admin')
param entraAdminDisplayName string = 'SQL Admins'

@description('Principal type of the admin (User or Group)')
@allowed(['User', 'Group'])
param entraAdminPrincipalType string = 'User'

var sqlServerName = '${resourcePrefix}-sql'
var databases = ['db-acme', 'db-nova', 'db-apex']

resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: true
      login: entraAdminDisplayName
      principalType: entraAdminPrincipalType
      sid: entraAdminObjectId
      tenantId: subscription().tenantId
    }
  }
}

// Allow Azure services to access the SQL server
resource firewallAzure 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlDatabases 'Microsoft.Sql/servers/databases@2023-05-01-preview' = [
  for db in databases: {
    parent: sqlServer
    name: db
    location: location
    sku: {
      name: 'Basic'
      tier: 'Basic'
      capacity: 5
    }
    properties: {
      collation: 'SQL_Latin1_General_CP1_CI_AS'
      maxSizeBytes: 2147483648 // 2GB
    }
  }
]

output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlServerName string = sqlServer.name
output databaseNames array = databases
