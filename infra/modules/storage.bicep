// ============================================================
// Azure Storage Account
// ============================================================
// Conditionally creates a Storage Account. When an existing
// resource ID is provided, creation is skipped and the ID is
// passed through in outputs.
// ============================================================

@description('Azure region')
param location string

@description('Resource name prefix')
param resourcePrefix string

@description('Existing Storage Account resource ID (empty = create new)')
param existingStorageId string = ''

var createStorage = empty(existingStorageId)
var storageName = replace('${resourcePrefix}st', '-', '')

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = if (createStorage) {
  name: storageName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

output storageId string = createStorage ? storage.id : existingStorageId
output storageName string = createStorage ? storage.name : last(split(existingStorageId, '/'))
