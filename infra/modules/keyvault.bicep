@description('Azure region.')
param location string

@description('Environment identifier used in resource naming.')
param environment string

param tags object

@secure()
@description('Azure OpenAI API key.')
param openAiKey string

@description('Application Insights connection string.')
param appInsightsConnectionString string

@description('SQL Server fully qualified domain name.')
param sqlServerFqdn string

@description('SQL Server administrator login.')
param sqlAdminLogin string

@secure()
@description('SQL Server administrator password.')
param sqlAdminPassword string

// Key Vault name: globally unique, max 24 chars, alphanumeric + hyphens.
var kvName = 'kv-inrdc-${take(uniqueString(resourceGroup().id), 8)}'

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    // RBAC-based access — no legacy access policies needed.
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    // Purge protection disabled for demo so the vault can be fully deleted.
    enablePurgeProtection: false
  }
}

// ── Secrets ───────────────────────────────────────────────────────────────────

resource secretOpenAiKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'openai-api-key'
  properties: { value: openAiKey }
}

resource secretAppInsights 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'appinsights-connection-string'
  properties: { value: appInsightsConnectionString }
}

// Connection strings use admin credentials initially.
// After running database/init-schema.sql, rotate these secrets to use ai_agent_ro.
resource secretAcme 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'sql-connstr-acme'
  properties: {
    value: 'Server=tcp:${sqlServerFqdn},1433;Initial Catalog=db-acme;Persist Security Info=False;User ID=${sqlAdminLogin};Password=${sqlAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
  }
}

resource secretNova 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'sql-connstr-nova'
  properties: {
    value: 'Server=tcp:${sqlServerFqdn},1433;Initial Catalog=db-nova;Persist Security Info=False;User ID=${sqlAdminLogin};Password=${sqlAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
  }
}

resource secretApex 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'sql-connstr-apex'
  properties: {
    value: 'Server=tcp:${sqlServerFqdn},1433;Initial Catalog=db-apex;Persist Security Info=False;User ID=${sqlAdminLogin};Password=${sqlAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
