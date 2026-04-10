// ============================================================
// InRiver-DataCase: Root Bicep Template
// ============================================================

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('SQL administrator password')
@secure()
param sqlAdminPassword string

@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param envName string = 'dev'

var projectName = 'inriver'
var resourcePrefix = '${projectName}-${envName}'

// ---- Managed Identity ----
module identity 'modules/identity.bicep' = {
  name: 'identity-deployment'
  params: {
    location: location
    resourcePrefix: resourcePrefix
  }
}

// ---- Azure Container Registry ----
module acr 'modules/acr.bicep' = {
  name: 'acr-deployment'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    identityPrincipalId: identity.outputs.principalId
  }
}

// ---- Azure SQL Server + Databases ----
module sql 'modules/sql.bicep' = {
  name: 'sql-deployment'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    sqlAdminPassword: sqlAdminPassword
  }
}

// ---- Key Vault ----
module keyvault 'modules/keyvault.bicep' = {
  name: 'keyvault-deployment'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    identityPrincipalId: identity.outputs.principalId
    sqlServerFqdn: sql.outputs.sqlServerFqdn
    sqlDatabaseNames: sql.outputs.databaseNames
  }
}

// ---- Container Apps ----
module containerApps 'modules/container-apps.bicep' = {
  name: 'container-apps-deployment'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    acrLoginServer: acr.outputs.loginServer
    identityId: identity.outputs.identityId
    identityClientId: identity.outputs.clientId
    keyVaultName: keyvault.outputs.keyVaultName
  }
}

// ---- Outputs ----
output acrLoginServer string = acr.outputs.loginServer
output sqlServerFqdn string = sql.outputs.sqlServerFqdn
output frontendUrl string = containerApps.outputs.frontendUrl
output backendUrl string = containerApps.outputs.backendUrl
output keyVaultName string = keyvault.outputs.keyVaultName
output identityClientId string = identity.outputs.clientId
