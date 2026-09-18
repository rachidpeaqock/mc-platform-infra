// ============================================================
// Stage 1 of 2 — foundation: what has to exist before any secret does
// ============================================================
// The estate deploys in two stages, on purpose, because the second needs
// a secret the first creates the place for:
//
//   1. foundation.bicep   identity, monitoring, registry, Key Vault
//      → runbook step: generate the database passwords INTO the vault
//   2. platform.bicep     database, storage, container apps, jobs,
//                         static web apps, alerts — reading those secrets
//
// One template with a "create the vault, then read from it" dependency
// would need the passwords as parameters on the first run and a vault
// reference on every later one; two templates and a bootstrap step in
// between is the honest shape of that ordering.
//
//   az deployment group create -g rg-milestone-command-dev \
//     -f bicep/foundation.bicep -p bicep/foundation.dev.bicepparam
//
// Everything is idempotent: re-running adopts what exists under the same
// names (the workspace, App Insights and the three Static Web Apps were
// created by hand before this file existed).

targetScope = 'resourceGroup'

@description('Environment discriminator: dev, prod')
@allowed(['dev', 'prod'])
param env string

@description('Region for everything that is not a Static Web App. francecentral in dev — westeurope refused the trial subscription.')
param location string = resourceGroup().location

@description('Where alerts are sent')
param opsEmail string

@description('Object id of the person or pipeline identity running the deployment. Gets Key Vault Secrets Officer so the bootstrap step can write the passwords.')
param deployerPrincipalId string

// One identity for all the apps and jobs: AcrPull on the registry, Secrets
// User on the vault. Per-app identities would be finer-grained and would
// buy nothing while every app reads the same registry and no app may
// read another's secret anyway — the secret NAMES are per service and an
// app only references its own. Revisit if a service ever holds a secret
// another must not see even in principle.
resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-mc-apps-${env}'
  location: location
}

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    env: env
    location: location
    opsEmail: opsEmail
    retentionDays: env == 'prod' ? 90 : 30
  }
}

module registry 'modules/registry.bicep' = {
  name: 'registry'
  params: {
    env: env
    location: location
    pullPrincipalId: identity.properties.principalId
  }
}

module vault 'modules/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    env: env
    location: location
    readerPrincipalId: identity.properties.principalId
    deployerPrincipalId: deployerPrincipalId
  }
}

output identityId string = identity.id
output identityPrincipalId string = identity.properties.principalId
output registryLoginServer string = registry.outputs.loginServer
output registryName string = registry.outputs.name
output keyVaultName string = vault.outputs.name
output keyVaultUri string = vault.outputs.uri
output workspaceId string = monitoring.outputs.workspaceId
output actionGroupId string = monitoring.outputs.actionGroupId

// What the runbook's bootstrap step must put in the vault before stage 2.
output secretsToCreate array = [
  'pg-admin-password'
  'pg-milestone-svc-password'
  'pg-identity-svc-password'
  'pg-template-svc-password'
]
