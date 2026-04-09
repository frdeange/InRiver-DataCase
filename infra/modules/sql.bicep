@description('Azure region.')
param location string

@description('Environment identifier used in resource naming.')
param environment string

param tags object

@description('SQL Server administrator login.')
param sqlAdminLogin string

@secure()
@description('SQL Server administrator password.')
param sqlAdminPassword string

var serverName = 'sql-inrdc-${environment}-${take(uniqueString(resourceGroup().id), 6)}'

// ── SQL Logical Server ────────────────────────────────────────────────────────

resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: serverName
  location: location
  tags: tags
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
  }
}

// Allow Azure services (0.0.0.0/0.0.0.0 is the special "Azure services" sentinel).
resource firewallAzureServices 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAllAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// ── Databases (Serverless, GP_S_Gen5_1, auto-pause 60 min) ───────────────────
// All three databases share the same tier settings — PIM schema, different customer data.

var dbSku = {
  name: 'GP_S_Gen5_1'
  tier: 'GeneralPurpose'
  family: 'Gen5'
  capacity: 1
}

var dbProperties = {
  collation: 'SQL_Latin1_General_CP1_CI_AS'
  autoPauseDelay: 60
  minCapacity: '0.5'
  requestedBackupStorageRedundancy: 'Local'
}

resource dbAcme 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: 'db-acme'
  location: location
  tags: union(tags, { customer: 'acme-corp' })
  sku: dbSku
  properties: dbProperties
}

resource dbNova 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: 'db-nova'
  location: location
  tags: union(tags, { customer: 'nova-retail' })
  sku: dbSku
  properties: dbProperties
}

resource dbApex 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: 'db-apex'
  location: location
  tags: union(tags, { customer: 'apex-distribution' })
  sku: dbSku
  properties: dbProperties
}

// ── Outputs ───────────────────────────────────────────────────────────────────

output fqdn string = sqlServer.properties.fullyQualifiedDomainName
output serverName string = sqlServer.name
output databaseNames array = [dbAcme.name, dbNova.name, dbApex.name]
