// ============================================================
// One Spring Boot service on Container Apps
// ============================================================
// The same shape for all five: pull from ACR with the shared identity,
// read secrets from Key Vault with the same identity, liveness and
// readiness on the actuator probes every service already exposes, and
// the JVM's heap sized by the container limit (JAVA_OPTS in each
// Dockerfile). Differences between services are inputs, not copies.
//
// Revision mode is Single: `az containerapp update --image` from the
// pipeline creates a new revision and shifts all traffic when its
// readiness probe passes; the previous revision stays for rollback
// (runbook §3).

@description('App name. Also the internal DNS name other apps use — the gateway\'s routes depend on these.')
param name string

param location string

@description('Managed environment resource id')
param environmentId string

@description('User-assigned identity that pulls images and reads secrets')
param identityId string

@description('Full image reference, e.g. acr.azurecr.io/mc-milestone-service:main')
param image string

@description('ACR login server the image is pulled from')
param registryServer string

@description('Port the service listens on (server.port)')
param port int

@description('Reachable from the internet? Only the gateway. Everything else is internal to the environment.')
param external bool = false

@description('Replicas. The gateway and milestone-service keep one warm (the hourly sweeper needs a live process; the front door must answer). The rest may scale to zero.')
param minReplicas int = 0
param maxReplicas int = 3

@description('vCPU and memory per replica. Spring Boot 4 on virtual threads is comfortable at 0.5 / 1Gi.')
param cpu string = '0.5'
param memory string = '1Gi'

@description('Plain environment variables: [{ name, value }]')
param envVars array = []

@description('Secrets from Key Vault: [{ name: <secret ref used in envVars>, envName: <variable name>, keyVaultUrl: <secret URL> }]')
param secrets array = []

@description('Origins CORS must admit at the ingress. Empty leaves CORS to the app (the gateway does its own).')
param corsOrigins array = []

// Each Key Vault secret becomes one environment variable, by reference.
var secretEnv = [for s in secrets: {
  name: s.envName
  secretRef: s.name
}]

resource app 'Microsoft.App/containerApps@2024-03-01' = {
  name: name
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: environmentId
    workloadProfileName: 'Consumption'
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: external
        targetPort: port
        transport: 'http'
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
        corsPolicy: empty(corsOrigins) ? null : {
          allowedOrigins: corsOrigins
          allowedMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS']
          allowedHeaders: ['*']
          exposeHeaders: ['ETag', 'Location']
          allowCredentials: false
          maxAge: 3600
        }
      }
      registries: [
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
          resources: {
            cpu: json(cpu)
            memory: memory
          }
          env: concat(envVars, secretEnv)
          probes: [
            {
              // Slow start is a JVM fact. The startup probe holds the other
              // two off for up to 120 s so a cold replica is not restarted
              // for being a JVM.
              type: 'Startup'
              httpGet: { path: '/actuator/health/liveness', port: port }
              periodSeconds: 5
              failureThreshold: 24
            }
            {
              type: 'Liveness'
              httpGet: { path: '/actuator/health/liveness', port: port }
              periodSeconds: 15
              failureThreshold: 3
            }
            {
              // Readiness includes the datasource where there is one, so a
              // replica that has lost the database stops receiving traffic
              // without being killed.
              type: 'Readiness'
              httpGet: { path: '/actuator/health/readiness', port: port }
              periodSeconds: 10
              failureThreshold: 3
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: [
          {
            name: 'http'
            http: {
              metadata: {
                concurrentRequests: '50'
              }
            }
          }
        ]
      }
    }
  }
}

output name string = app.name
output fqdn string = app.properties.configuration.ingress.fqdn
output id string = app.id
