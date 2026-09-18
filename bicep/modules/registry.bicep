// ============================================================
// Container Registry — the images Container Apps pull from
// ============================================================
// java-service.yml already pushes every service image here as well as
// to GHCR whenever the ACR_NAME variable is set on the calling repo
// (one build, both registries, identical digest). GHCR remains the copy
// a developer pulls for compose; ACR is the copy the cloud runs, pulled
// with a managed identity so nothing at runtime holds a credential.

@description('Environment discriminator: dev, prod')
param env string

param location string

@description('Principal id of the identity the container apps pull with')
param pullPrincipalId string

// ACR names: 5–50 alphanumerics, globally unique, no hyphens.
var name = 'acrmilestonecommand${env}'

// AcrPull
var acrPullRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  sku: {
    // Basic: 10 GiB, enough for five services × a few tags. Geo-replication
    // and private endpoints are Premium and a production concern.
    name: 'Basic'
  }
  properties: {
    // The pipeline signs in with OIDC (az acr login), the apps with a
    // managed identity. The admin user is a shared password nobody
    // should have; it stays off.
    adminUserEnabled: false
    // Untagged manifests pile up as CI pushes :main over and over.
    // Retention of untagged manifests is Premium-only, so the runbook
    // carries the `az acr manifest` purge instead.
  }
}

resource pull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(registry.id, pullPrincipalId, acrPullRoleId)
  scope: registry
  properties: {
    roleDefinitionId: acrPullRoleId
    principalId: pullPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output name string = registry.name
output loginServer string = registry.properties.loginServer
