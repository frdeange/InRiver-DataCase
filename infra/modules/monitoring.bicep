// ============================================================
// Log Analytics Workspace + Application Insights
// ============================================================
// Conditionally creates each resource. When an existing resource
// ID is provided, the module references the pre-provisioned
// resource instead of creating a new one.
// ============================================================

@description('Azure region')
param location string

@description('Resource name prefix')
param resourcePrefix string

@description('Existing Log Analytics workspace resource ID (empty = create new)')
param existingLogAnalyticsId string = ''

@description('Existing Application Insights resource ID (empty = create new)')
param existingAppInsightsId string = ''

// Determine if we need to create new resources
var createLogAnalytics = empty(existingLogAnalyticsId)
var createAppInsights = empty(existingAppInsightsId)

// ---- Log Analytics Workspace ----

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (createLogAnalytics) {
  name: '${resourcePrefix}-logs'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource existingLogAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = if (!createLogAnalytics) {
  name: last(split(existingLogAnalyticsId, '/'))
}

// ---- Application Insights ----

resource appInsights 'Microsoft.Insights/components@2020-02-02' = if (createAppInsights) {
  name: '${resourcePrefix}-appi'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: createLogAnalytics ? logAnalytics.id : existingLogAnalyticsId
    IngestionMode: 'LogAnalytics'
  }
}

resource existingAppInsights 'Microsoft.Insights/components@2020-02-02' existing = if (!createAppInsights) {
  name: last(split(existingAppInsightsId, '/'))
}

// ---- Outputs ----
// Always resolve to the correct resource (new or existing)

output logAnalyticsId string = createLogAnalytics ? logAnalytics.id : existingLogAnalyticsId
output logAnalyticsCustomerId string = createLogAnalytics ? logAnalytics.properties.customerId : existingLogAnalytics.properties.customerId
output logAnalyticsKey string = createLogAnalytics ? logAnalytics.listKeys().primarySharedKey : existingLogAnalytics.listKeys().primarySharedKey
output appInsightsId string = createAppInsights ? appInsights.id : existingAppInsightsId
output appInsightsConnectionString string = createAppInsights ? appInsights.properties.ConnectionString : existingAppInsights.properties.ConnectionString
output appInsightsInstrumentationKey string = createAppInsights ? appInsights.properties.InstrumentationKey : existingAppInsights.properties.InstrumentationKey
