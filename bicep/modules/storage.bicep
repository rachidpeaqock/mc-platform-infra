// ============================================================
// Evidence storage — the photographs a crew lead takes on a slip
// ============================================================
// milestone-service (MC-424, contract 2.5.0) writes digest-checked blobs
// to one container and reads them back through the API; nothing else
// touches this account. The service takes a connection string
// (EVIDENCE_STORAGE_CONNECTION_STRING), which is why the key is written
// to Key Vault here rather than the app being granted a data role —
// swapping to `DefaultAzureCredential` is a service change, recorded in
// the runbook's hardening list.

@description('Environment discriminator: dev, prod')
param env string

param location string

@description('Key Vault the connection string is written to')
param keyVaultName string

@description('Container name the service is configured with (EVIDENCE_CONTAINER)')
param containerName string = 'evidence'

// 3–24 lowercase alphanumerics, globally unique.
var name = 'stmcevidence${env}${take(uniqueString(resourceGroup().id), 6)}'

resource account 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: name
  location: location
  kind: 'StorageV2'
  sku: {
    // LRS in dev. Evidence is legal material in a claims file; prod moves
    // to ZRS or GRS, which is a SKU change and nothing else.
    name: env == 'prod' ? 'Standard_GRS' : 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    // Every read goes through milestone-service, which checks the caller's
    // role and the digest. A photograph must never be reachable by URL.
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource blob 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: account
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      // A blob deleted by mistake — or by a bug in the digest check — is
      // recoverable for a month. The audit row that points at it outlives
      // it regardless.
      enabled: true
      days: 30
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 30
    }
  }
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blob
  name: containerName
  properties: {
    publicAccess: 'None'
  }
}

resource vault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// The key never leaves ARM: listKeys() is evaluated inside the deployment
// and the value lands in the vault. It appears in no output and no log.
resource connectionString 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vault
  name: 'evidence-connection-string'
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${account.name};AccountKey=${account.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
    contentType: 'Azure Storage connection string'
  }
}

output accountName string = account.name
output containerName string = container.name
