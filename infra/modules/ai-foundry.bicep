// ============================================================
// Azure AI Foundry (new architecture — 2025-10-01-preview)
// ============================================================
// Structure:
//   CognitiveServices/accounts          (AI Services)
//     └─ accounts/projects              (AI Project — child resource)
//     └─ accounts/deployments           (Model deployments)
//     └─ accounts/connections            (Storage, App Insights, etc.)
//
// No more ML Hub/Workspace. Everything under CognitiveServices.
// ============================================================

@description('Azure region')
param location string

@description('Resource name prefix')
param resourcePrefix string

@description('Existing Azure AI Project resource ID (empty = create new)')
param existingAiProjectId string = ''

@description('Storage Account resource ID (for account connection)')
param storageId string

@description('Storage Account name')
param storageName string

@description('Application Insights resource ID (for account connection)')
param appInsightsId string

@description('Application Insights instrumentation key (required for ApiKey auth on connection)')
@secure()
param appInsightsInstrumentationKey string

@description('Principal ID of managed identity for Cognitive Services OpenAI User role')
param identityPrincipalId string

@description('Model to deploy (e.g. gpt-4o, gpt-5.4)')
param modelName string = 'gpt-5.4'

@description('Model version')
param modelVersion string = '2026-03-05'

@description('Model deployment SKU name')
param modelSkuName string = 'GlobalStandard'

@description('Model deployment capacity (tokens per minute in thousands)')
param modelCapacity int = 100

var createAiFoundry = empty(existingAiProjectId)
var aiServicesName = '${resourcePrefix}-ais'
var projectName = '${resourcePrefix}-project'

// ============================================================
// 1. AI Services Account
// ============================================================

resource aiServices 'Microsoft.CognitiveServices/accounts@2025-10-01-preview' = if (createAiFoundry) {
  name: aiServicesName
  location: location
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: aiServicesName
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
    allowProjectManagement: true
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
  }
}

// ============================================================
// 2. AI Project (child of AI Services account)
// ============================================================

resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-10-01-preview' = if (createAiFoundry) {
  parent: aiServices
  name: projectName
  location: location
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: '${resourcePrefix} Project'
    description: 'InRiver-DataCase PoC project'
  }
}

// ============================================================
// 3. Model Deployment (gpt-5.4 by default)
// ============================================================

resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-10-01-preview' = if (createAiFoundry) {
  parent: aiServices
  name: modelName
  sku: {
    name: modelSkuName
    capacity: modelCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    raiPolicyName: 'Microsoft.DefaultV2'
  }
}

// ============================================================
// 4. Account-level Connections (Storage + App Insights)
// ============================================================

resource storageConnection 'Microsoft.CognitiveServices/accounts/connections@2025-10-01-preview' = if (createAiFoundry) {
  parent: aiServices
  name: '${storageName}-connection'
  properties: {
    authType: 'AAD'
    category: 'AzureStorageAccount'
    target: 'https://${storageName}.blob.core.windows.net/'
    useWorkspaceManagedIdentity: false
    isSharedToAll: true
    sharedUserList: []
    peRequirement: 'NotRequired'
    peStatus: 'NotApplicable'
    metadata: {
      ApiType: 'Azure'
      ResourceId: storageId
      location: location
    }
  }
}

resource appInsightsConnection 'Microsoft.CognitiveServices/accounts/connections@2025-10-01-preview' = if (createAiFoundry) {
  parent: aiServices
  name: 'appinsights-connection'
  properties: {
    authType: 'ApiKey'
    category: 'AppInsights'
    target: appInsightsId
    credentials: {
      key: appInsightsInstrumentationKey
    }
    useWorkspaceManagedIdentity: false
    isSharedToAll: true
    sharedUserList: []
    peRequirement: 'NotRequired'
    peStatus: 'NotApplicable'
    metadata: {
      ApiType: 'Azure'
      ResourceId: appInsightsId
    }
  }
}

// ============================================================
// 5. Role Assignment — Cognitive Services OpenAI User
// ============================================================

var cognitiveServicesOpenAiUserRoleId = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'

resource openAiUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (createAiFoundry) {
  name: guid(aiServicesName, identityPrincipalId, cognitiveServicesOpenAiUserRoleId)
  scope: aiServices
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      cognitiveServicesOpenAiUserRoleId
    )
    principalId: identityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ============================================================
// Outputs
// ============================================================

// Project endpoint: https://{account}.services.ai.azure.com/api/projects/{project}
output aiProjectEndpoint string = createAiFoundry
  ? 'https://${aiServicesName}.services.ai.azure.com/api/projects/${projectName}'
  : ''
output aiServicesEndpoint string = createAiFoundry
  ? 'https://${aiServicesName}.services.ai.azure.com/'
  : ''
output aiProjectId string = createAiFoundry ? aiProject.id : existingAiProjectId
output modelDeploymentName string = createAiFoundry ? modelName : ''
output aiServicesName string = createAiFoundry ? aiServicesName : ''
