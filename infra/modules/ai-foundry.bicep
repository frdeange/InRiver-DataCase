// ============================================================
// Azure AI Foundry: AI Services + AI Hub + AI Project
// ============================================================
// Conditionally creates the full AI Foundry stack. When an
// existing AI Project ID is provided, all creation is skipped.
// ============================================================

@description('Azure region')
param location string

@description('Resource name prefix')
param resourcePrefix string

@description('Existing Azure AI Project resource ID (empty = create new)')
param existingAiProjectId string = ''

@description('Storage Account resource ID (required for AI Hub)')
param storageId string

@description('Key Vault resource ID (required for AI Hub)')
param keyVaultId string

@description('Application Insights resource ID (required for AI Hub)')
param appInsightsId string

@description('Principal ID of managed identity for Cognitive Services OpenAI User role')
param identityPrincipalId string

@description('Model to deploy (e.g. gpt-4o, gpt-5.4)')
param modelName string = 'gpt-4o'

@description('Model version (empty = latest)')
param modelVersion string = ''

@description('Model deployment SKU name')
param modelSkuName string = 'GlobalStandard'

@description('Model deployment capacity (thousands of tokens per minute)')
param modelCapacity int = 30

var createAiFoundry = empty(existingAiProjectId)

// ---- Azure AI Services account ----

resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = if (createAiFoundry) {
  name: '${resourcePrefix}-ais'
  location: location
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: '${resourcePrefix}-ais'
    publicNetworkAccess: 'Enabled'
  }
}

// ---- Model Deployment ----
// Deploys the specified model (e.g. gpt-4o) so the agents have
// an actual model endpoint to call via FoundryChatClient.

var deploymentName = modelName // Use model name as deployment name

resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = if (createAiFoundry) {
  parent: aiServices
  name: deploymentName
  sku: {
    name: modelSkuName
    capacity: modelCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: !empty(modelVersion) ? modelVersion : null
    }
    raiPolicyName: 'Microsoft.DefaultV2'
  }
}

// ---- Azure AI Hub ----

resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = if (createAiFoundry) {
  name: '${resourcePrefix}-hub'
  location: location
  kind: 'Hub'
  sku: {
    name: 'Basic'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: '${resourcePrefix} AI Hub'
    storageAccount: storageId
    keyVault: keyVaultId
    applicationInsights: appInsightsId
  }
}

// ---- AI Services connection on the hub ----

resource aiServicesConnection 'Microsoft.MachineLearningServices/workspaces/connections@2024-10-01' = if (createAiFoundry) {
  parent: aiHub
  name: 'Default_AIServices'
  properties: {
    category: 'AIServices'
    target: aiServices.properties.endpoint
    authType: 'AAD'
    metadata: {
      ApiType: 'Azure'
      ResourceId: aiServices.id
    }
  }
}

// ---- Azure AI Project ----

resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = if (createAiFoundry) {
  name: '${resourcePrefix}-project'
  location: location
  kind: 'Project'
  sku: {
    name: 'Basic'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: '${resourcePrefix} AI Project'
    hubResourceId: aiHub.id
  }
}

// ---- Cognitive Services OpenAI User role for managed identity ----

var cognitiveServicesOpenAiUserRoleId = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'

resource openAiUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (createAiFoundry) {
  name: guid('${resourcePrefix}-ais', identityPrincipalId, cognitiveServicesOpenAiUserRoleId)
  scope: aiServices
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesOpenAiUserRoleId)
    principalId: identityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ---- Existing project reference (when reusing) ----

resource existingProject 'Microsoft.MachineLearningServices/workspaces@2024-10-01' existing = if (!createAiFoundry) {
  name: last(split(existingAiProjectId, '/'))
}

// ---- Outputs ----

output aiProjectId string = createAiFoundry ? aiProject.id : existingAiProjectId
output aiProjectEndpoint string = createAiFoundry ? aiProject.properties.discoveryUrl : existingProject.properties.discoveryUrl
output aiServicesEndpoint string = createAiFoundry ? aiServices.properties.endpoint : ''
output modelDeploymentName string = createAiFoundry ? deploymentName : ''
