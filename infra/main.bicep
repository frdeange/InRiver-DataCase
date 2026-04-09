targetScope = 'resourceGroup'

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Environment identifier used in resource naming.')
param environment string = 'demo'

@description('SQL Server administrator login name.')
param sqlAdminLogin string

@secure()
@description('SQL Server administrator password.')
param sqlAdminPassword string

@secure()
@description('Application Insights connection string from the existing AI Foundry workspace.')
param appInsightsConnectionString string

@description('Azure OpenAI endpoint URL (e.g. https://<name>.openai.azure.com/).')
param openAiEndpoint string

@secure()
@description('Azure OpenAI API key.')
param openAiKey string

var tags = {
  project: 'inriver-datacase'
  environment: environment
}

// ── SQL Server + Databases ────────────────────────────────────────────────────

module sql 'modules/sql.bicep' = {
  name: 'sqlDeploy'
  params: {
    location: location
    environment: environment
    tags: tags
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPassword: sqlAdminPassword
  }
}

// ── Key Vault (depends on SQL for FQDN) ──────────────────────────────────────

module keyVault 'modules/keyvault.bicep' = {
  name: 'keyVaultDeploy'
  params: {
    location: location
    environment: environment
    tags: tags
    openAiKey: openAiKey
    appInsightsConnectionString: appInsightsConnectionString
    sqlServerFqdn: sql.outputs.fqdn
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPassword: sqlAdminPassword
  }
}

// ── Container Apps Environment + Apps ────────────────────────────────────────

module containerApps 'modules/container-apps.bicep' = {
  name: 'containerAppsDeploy'
  params: {
    location: location
    environment: environment
    tags: tags
    keyVaultName: keyVault.outputs.keyVaultName
    appInsightsConnectionString: appInsightsConnectionString
    openAiEndpoint: openAiEndpoint
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

output keyVaultName string = keyVault.outputs.keyVaultName
output sqlServerFqdn string = sql.outputs.fqdn
output containerAppsEnvironmentId string = containerApps.outputs.environmentId
output backendUrl string = containerApps.outputs.backendUrl
output frontendUrl string = containerApps.outputs.frontendUrl
