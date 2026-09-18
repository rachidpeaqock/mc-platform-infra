// ============================================================
// Key Vault — every runtime secret, read by managed identity
// ============================================================
// Bicep declares the vault and who may read it. It does NOT declare the
// secrets, with one exception. The database passwords are generated once
// by the runbook's bootstrap step and written straight into the vault
// with `az keyvault secret set`, so no password is ever a template
// parameter, a pipeline variable, or a line in a terminal history. The
// container apps reference the secrets by URL and the platform fetches
// them with the apps' identity at start.
//
// Secrets this vault is expected to hold — the names are the contract
// the container-app modules and the runbook share:
//
//   pg-admin-password            Flexible Server administrator
//   pg-milestone-svc-password    one login per service, no cross-database
//   pg-identity-svc-password     grants (platform-architecture.md §6)
//   pg-template-svc-password
//   evidence-connection-string   written by storage.bicep — the one
//                                exception, because Bicep created the
//                                account and can read its key without
//                                the key ever leaving ARM

@description('Environment discriminator: dev, prod')
param env string

param location string

@description('Principal id of the identity the container apps read secrets with')
param readerPrincipalId string

@description('Object id of whoever deploys — gets Secrets Officer so the bootstrap step can write the passwords')
param deployerPrincipalId string

// Vault names: 3–24 chars, globally unique. Deterministic on purpose —
// platform.dev.bicepparam reads pg-admin-password out of this vault with
// getSecret(), which takes a literal name, so a uniqueString() suffix
// here would have to be copied by hand into that file.
var name = 'kv-mc-milestone-${env}'

// Key Vault Secrets User / Key Vault Secrets Officer
var secretsUserRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
var secretsOfficerRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')

resource vault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  properties: {
    tenantId: tenant().tenantId
    sku: { family: 'A', name: 'standard' }
    // RBAC, not access policies: the same role model as everything else
    // in the group, and no second permission system to audit.
    enableRbacAuthorization: true
    // A deleted vault with the database passwords in it must be
    // recoverable for the time it takes to notice.
    enableSoftDelete: true
    softDeleteRetentionInDays: 30
    // Off in dev so a torn-down environment can be recreated under the
    // same name. Prod turns it on: a purge-protected vault cannot be
    // destroyed by anyone, including its owner, before retention ends.
    enablePurgeProtection: env == 'prod' ? true : null
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource readSecrets 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(vault.id, readerPrincipalId, secretsUserRoleId)
  scope: vault
  properties: {
    roleDefinitionId: secretsUserRoleId
    principalId: readerPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource writeSecrets 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(vault.id, deployerPrincipalId, secretsOfficerRoleId)
  scope: vault
  properties: {
    roleDefinitionId: secretsOfficerRoleId
    principalId: deployerPrincipalId
  }
}

output name string = vault.name
output uri string = vault.properties.vaultUri
output id string = vault.id
