// One secret into the vault, through ARM.
//
// The development machine cannot reach the vault's data plane (TLS
// interception), so `az keyvault secret set` fails there. A deployment can:
// the value travels as a secure parameter that ARM neither logs nor echoes,
// and `az deployment group show` answers "SecureString" for it, not the
// value. vault-bootstrap.bicep is the same idea for the first four secrets;
// this is the general one, for rotations (runbook §4, §11).
//
//   az deployment group create -g rg-milestone-command-dev -n automation-secret \
//     -f bicep/vault-secret.bicep -p name=automation-client-secret value=$new -o none
targetScope = 'resourceGroup'

param vaultName string = 'kv-mc-milestone-dev'

@description('Secret name, e.g. automation-client-secret')
param name string

@secure()
param value string

resource vault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: vaultName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vault
  name: name
  properties: {
    value: value
  }
}
