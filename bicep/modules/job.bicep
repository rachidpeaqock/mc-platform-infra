// ============================================================
// A one-shot Container Apps Job — run it, it exits, its log stays
// ============================================================
// Two uses: the Flyway migration per service (migrate, then deploy — the
// ordering MC-304 made a rule) and the database bootstrap that creates
// the per-service logins. Both are `az containerapp job start`, both
// read their passwords from Key Vault with the shared identity, neither
// runs on a schedule.

@description('Job name, e.g. job-migrate-milestone')
param name string

param location string

param environmentId string

@description('User-assigned identity that pulls the image and reads secrets')
param identityId string

@description('Full image reference')
param image string

@description('ACR login server, when the image is in ACR. Empty for a public image such as postgres:17-alpine.')
param registryServer string = ''

@description('Container command. Empty keeps the image\'s entrypoint.')
param command array = []

param args array = []

@description('Plain environment variables: [{ name, value }]')
param envVars array = []

@description('Secrets from Key Vault: [{ name, envName, keyVaultUrl }]')
param secrets array = []

@description('Seconds a run may take before the platform kills it. Flyway on an empty database is seconds; a long V-script on prod data may not be.')
param timeoutSeconds int = 900

// Each Key Vault secret becomes one environment variable, by reference.
var secretEnv = [for s in secrets: {
  name: s.envName
  secretRef: s.name
}]

resource job 'Microsoft.App/jobs@2024-03-01' = {
  name: name
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  properties: {
    environmentId: environmentId
    workloadProfileName: 'Consumption'
    configuration: {
      triggerType: 'Manual'
      replicaTimeout: timeoutSeconds
      // A migration that failed must not be retried blind: Flyway leaves
      // the failed row and the person reading the log decides.
      replicaRetryLimit: 0
      manualTriggerConfig: {
        parallelism: 1
        replicaCompletionCount: 1
      }
      registries: empty(registryServer) ? [] : [
        {
          server: registryServer
          identity: identityId
        }
      ]
      secrets: [for s in secrets: {
        name: s.name
        keyVaultUrl: s.keyVaultUrl
        identity: identityId
      }]
    }
    template: {
      containers: [
        {
          name: name
          image: image
          command: empty(command) ? null : command
          args: empty(args) ? null : args
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          env: concat(envVars, secretEnv)
        }
      ]
    }
  }
}

output name string = job.name
output id string = job.id
