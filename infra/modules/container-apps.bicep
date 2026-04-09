@description('Azure region.')
param location string

@description('Environment identifier used in resource naming.')
param environment string

param tags object

@description('Key Vault name (used to grant the managed identity access).')
param keyVaultName string

@description('Application Insights connection string (injected as a container secret).')
param appInsightsConnectionString string

@description('Azure OpenAI endpoint URL.')
param openAiEndpoint string

var suffix = take(uniqueString(resourceGroup().id), 6)
var envName = 'cae-inrdc-${environment}-${suffix}'
var backendAppName = 'ca-backend-${environment}-${suffix}'
var frontendAppName = 'ca-frontend-${environment}-${suffix}'
var lawName = 'law-inrdc-${environment}-${suffix}'
var identityName = 'id-inrdc-${environment}'

// ── Log Analytics Workspace (for Container Apps infra logs) ──────────────────

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: lawName
  location: location
  tags: tags
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
  }
}

// ── Container Apps Environment ────────────────────────────────────────────────

resource containerAppsEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: envName
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

// ── User-Assigned Managed Identity ────────────────────────────────────────────

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
  tags: tags
}

// ── Key Vault Secrets User role assignment ────────────────────────────────────

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// Role: Key Vault Secrets User (4633458b-17de-408a-b874-0445c86b69e6)
resource kvSecretsUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, managedIdentity.id, '4633458b-17de-408a-b874-0445c86b69e6')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6'
    )
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// ── Backend Container App (FastAPI) ───────────────────────────────────────────

resource backendApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: backendAppName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: { '${managedIdentity.id}': {} }
  }
  properties: {
    managedEnvironmentId: containerAppsEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8000
        transport: 'http'
        corsPolicy: {
          allowedOrigins: ['*']
          allowedMethods: ['GET', 'POST', 'OPTIONS']
          allowedHeaders: ['*']
        }
      }
      secrets: [
        { name: 'appinsights-connstr', value: appInsightsConnectionString }
      ]
    }
    template: {
      containers: [
        {
          name: 'backend'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: { cpu: json('0.5'), memory: '1Gi' }
          env: [
            { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', secretRef: 'appinsights-connstr' }
            { name: 'AZURE_OPENAI_ENDPOINT', value: openAiEndpoint }
            { name: 'AZURE_CLIENT_ID', value: managedIdentity.properties.clientId }
            { name: 'KEY_VAULT_URI', value: keyVault.properties.vaultUri }
          ]
        }
      ]
      scale: { minReplicas: 0, maxReplicas: 3 }
    }
  }
}

// ── Frontend Container App (React/Vite) ───────────────────────────────────────

resource frontendApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: frontendAppName
  location: location
  tags: tags
  properties: {
    managedEnvironmentId: containerAppsEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 3000
        transport: 'http'
      }
    }
    template: {
      containers: [
        {
          name: 'frontend'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: { cpu: json('0.25'), memory: '0.5Gi' }
          env: [
            { name: 'VITE_API_URL', value: 'https://${backendApp.properties.configuration.ingress.fqdn}' }
          ]
        }
      ]
      scale: { minReplicas: 0, maxReplicas: 3 }
    }
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

output environmentId string = containerAppsEnv.id
output backendUrl string = 'https://${backendApp.properties.configuration.ingress.fqdn}'
output frontendUrl string = 'https://${frontendApp.properties.configuration.ingress.fqdn}'
output managedIdentityClientId string = managedIdentity.properties.clientId
