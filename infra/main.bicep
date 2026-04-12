// ============================================================
// InRiver-DataCase: Root Bicep Template
// ============================================================
// Deployment orchestrator — wires all modules together.
// Supports both fresh deployments (creates all resources) and
// existing-resource deployments (references pre-provisioned
// resources by ID). Pass an existing*Id parameter to reuse
// a resource instead of creating a new one.
// ============================================================

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param envName string = 'dev'

// ---- Azure SQL AD-only auth ----

@description('Object ID of the Entra ID user/group for SQL admin')
param sqlEntraAdminObjectId string

@description('Display name of the SQL Entra admin')
param sqlEntraAdminDisplayName string = 'SQL Admins'

@description('Principal type of Entra admin: User or Group')
@allowed(['User', 'Group'])
param sqlEntraAdminPrincipalType string = 'User'

// ---- Existing-resource overrides (empty = create new) ----

@description('Existing Log Analytics workspace resource ID (empty = create new)')
param existingLogAnalyticsId string = ''

@description('Existing Application Insights resource ID (empty = create new)')
param existingAppInsightsId string = ''

@description('Existing Storage Account resource ID (empty = create new)')
param existingStorageId string = ''

@description('Existing Azure AI Project resource ID (empty = create new)')
param existingAiProjectId string = ''

// ---- AI Model deployment configuration ----

@description('AI model to deploy (e.g. gpt-4o, gpt-5.4)')
param aiModelName string = 'gpt-4o'

@description('AI model version (empty = default 2026-03-05)')
param aiModelVersion string = '2026-03-05'

@description('AI model deployment SKU (GlobalStandard, Standard, ProvisionedManaged)')
param aiModelSkuName string = 'GlobalStandard'

@description('AI model deployment capacity (thousands of tokens per minute)')
param aiModelCapacity int = 30

var projectName = 'inriver'
var resourcePrefix = '${projectName}-${envName}'

// ---- 1. Managed Identity ----
module identity 'modules/identity.bicep' = {
  name: 'identity-deployment'
  params: {
    location: location
    resourcePrefix: resourcePrefix
  }
}

// ---- 2. Monitoring (Log Analytics + Application Insights) ----
// If existing IDs are provided, the module references them
// instead of creating new resources.
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring-deployment'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    existingLogAnalyticsId: existingLogAnalyticsId
    existingAppInsightsId: existingAppInsightsId
  }
}

// ---- 3. Storage Account ----
// Conditionally created; pass existingStorageId to reuse.
module storage 'modules/storage.bicep' = {
  name: 'storage-deployment'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    existingStorageId: existingStorageId
  }
}

// ---- 4. Azure Container Registry ----
module acr 'modules/acr.bicep' = {
  name: 'acr-deployment'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    identityPrincipalId: identity.outputs.principalId
  }
}

// ---- 5. Azure SQL Server + Databases ----
module sql 'modules/sql.bicep' = {
  name: 'sql-deployment'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    entraAdminObjectId: sqlEntraAdminObjectId
    entraAdminDisplayName: sqlEntraAdminDisplayName
    entraAdminPrincipalType: sqlEntraAdminPrincipalType
  }
}

// ---- 6. Key Vault ----
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

// ---- 7. AI Foundry (new architecture: AI Services + Project) ----
// Creates AI Services account, project, model deployment, and connections.
// No ML Hub — everything lives under CognitiveServices/accounts.
module aiFoundry 'modules/ai-foundry.bicep' = {
  name: 'ai-foundry-deployment'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    existingAiProjectId: existingAiProjectId
    storageId: storage.outputs.storageId
    storageName: storage.outputs.storageName
    appInsightsId: monitoring.outputs.appInsightsId
    appInsightsInstrumentationKey: monitoring.outputs.appInsightsInstrumentationKey
    identityPrincipalId: identity.outputs.principalId
    modelName: aiModelName
    modelVersion: aiModelVersion
    modelSkuName: aiModelSkuName
    modelCapacity: aiModelCapacity
  }
}

// ---- 8. Container Apps ----
// Receives Log Analytics + App Insights from monitoring module
// and AI Project endpoint from aiFoundry module.
module containerApps 'modules/container-apps.bicep' = {
  name: 'container-apps-deployment'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    acrLoginServer: acr.outputs.loginServer
    identityId: identity.outputs.identityId
    identityClientId: identity.outputs.clientId
    keyVaultName: keyvault.outputs.keyVaultName
    logAnalyticsCustomerId: monitoring.outputs.logAnalyticsCustomerId
    logAnalyticsKey: monitoring.outputs.logAnalyticsKey
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    aiProjectEndpoint: aiFoundry.outputs.aiProjectEndpoint
    sqlServerFqdn: sql.outputs.sqlServerFqdn
  }
}

// ---- Outputs ----
output acrLoginServer string = acr.outputs.loginServer
output sqlServerFqdn string = sql.outputs.sqlServerFqdn
output frontendUrl string = containerApps.outputs.frontendUrl
output backendUrl string = containerApps.outputs.backendUrl
output orchestratorUrl string = containerApps.outputs.orchestratorUrl
output mcpToolsUrl string = containerApps.outputs.mcpToolsUrl
output keyVaultName string = keyvault.outputs.keyVaultName
output identityClientId string = identity.outputs.clientId
output appInsightsConnectionString string = monitoring.outputs.appInsightsConnectionString
output aiProjectEndpoint string = aiFoundry.outputs.aiProjectEndpoint
output modelDeploymentName string = aiFoundry.outputs.modelDeploymentName
output storageAccountName string = storage.outputs.storageName
