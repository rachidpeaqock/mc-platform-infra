// ============================================================
// Vault bootstrap — the passwords, written through ARM, once
// ============================================================
// The runbook's §1.3 was written as `az keyvault secret set`, which uses
// the vault's data plane (*.vault.azure.net). On 2026-09-19 that plane
// turned out to be unreachable from the development machine — the same
// corporate TLS wall that blocks the registry's — while ARM is fine. So
// the secrets are written as resources: same result, same vault, values
// carried as secure parameters that ARM neither logs nor echoes.
//
//   az deployment group create -g rg-milestone-command-dev -n vault-bootstrap \
//     -f bicep/vault-bootstrap.bicep \
//     -p existingAdminPassword=@<(az containerapp secret show … --query value -o tsv)
//
// ⚠️ Run ONCE. The three service passwords default to fresh GUIDs, so a
// second run would rotate them under the running services. Rotation is
// runbook §4 (set the secret, run the bootstrap job, restart the app),
// not a re-run of this file — and it is the reason this is not part of
// foundation.bicep.

targetScope = 'resourceGroup'

@description('The vault foundation.bicep created')
param vaultName string = 'kv-mc-milestone-dev'

@secure()
@description('The Flexible Server administrator password as it is today — read from the running app\'s secret, never typed')
param existingAdminPassword string

@secure()
@description('New. A GUID is 122 random bits; Postgres accepts it as a password.')
param milestoneSvcPassword string = newGuid()

@secure()
param identitySvcPassword string = newGuid()

@secure()
param templateSvcPassword string = newGuid()

resource vault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: vaultName
}

resource admin 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vault
  name: 'pg-admin-password'
  properties: { value: existingAdminPassword, contentType: 'PostgreSQL administrator (mcadmin)' }
}

resource milestone 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vault
  name: 'pg-milestone-svc-password'
  properties: { value: milestoneSvcPassword, contentType: 'PostgreSQL login milestone_svc' }
}

resource identity 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vault
  name: 'pg-identity-svc-password'
  properties: { value: identitySvcPassword, contentType: 'PostgreSQL login identity_svc' }
}

resource template 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vault
  name: 'pg-template-svc-password'
  properties: { value: templateSvcPassword, contentType: 'PostgreSQL login template_svc' }
}

output written array = [admin.name, milestone.name, identity.name, template.name]
