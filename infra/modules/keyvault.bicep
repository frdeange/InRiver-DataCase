// ============================================================
// Azure Key Vault with SQL Connection String Secrets
// ============================================================

@description('Azure region')
param location string

@description('Resource name prefix')
param resourcePrefix string

@description('Principal ID of managed identity for Key Vault Secrets User')
param identityPrincipalId string

@description('SQL Server FQDN')
param sqlServerFqdn string

@description('SQL database names')
param sqlDatabaseNames array

var kvName = replace('${resourcePrefix}-kv', '-', '')

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: false
  }
}

// Key Vault Secrets User role for managed identity
var kvSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

resource kvSecretsRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, identityPrincipalId, kvSecretsUserRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', kvSecretsUserRoleId)
    principalId: identityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// SQL connection string secrets for each tenant database
resource sqlSecrets 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = [
  for dbName in sqlDatabaseNames: {
    parent: keyVault
    name: 'sql-connstr-${dbName}'
    properties: {
      value: 'Server=tcp:${sqlServerFqdn},1433;Database=${dbName};Authentication=Active Directory Managed Identity;Encrypt=True;TrustServerCertificate=False;'
    }
  }
]

output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultId string = keyVault.id
