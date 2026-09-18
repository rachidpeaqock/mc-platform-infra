// ============================================================
// Stage 2 of 2 — platform: the running estate
// ============================================================
// Everything a request touches, from the Static Web App that serves the
// bundle to the row in Postgres: the database and its per-service
// databases, evidence storage, the Container Apps environment, the five
// services, the migration jobs, the bootstrap job, the four front ends,
// and the alerts over all of it.
//
// Requires stage 1 (foundation.bicep) and the vault secrets it lists.
//
//   az deployment group what-if -g rg-milestone-command-dev \
//     -f bicep/platform.bicep -p bicep/platform.dev.bicepparam
//   az deployment group create  -g rg-milestone-command-dev \
//     -f bicep/platform.bicep -p bicep/platform.dev.bicepparam
//
// Then, the first time only, in this order (runbook §1.6):
//   job-bootstrap-db → job-migrate-{milestone,identity,template} →
//   the services come up on their own (they restart until the schema
//   exists — SchemaVersionGuard, MC-304).
//
// What is deliberately NOT here, and what would make it appear:
//   Event Hubs (Kafka)   no service produces or consumes an event yet
//   Web PubSub           activity-service is parked (E5)
//   activity_db          same
//   Front Door           front-door.bicep, when the apps need one origin
//   Field app registration   waits on the iOS bundle id (MC-004)

targetScope = 'resourceGroup'

@description('Environment discriminator: dev, prod')
@allowed(['dev', 'prod'])
param env string

@description('Region for the container apps, database and storage')
param location string = resourceGroup().location

@description('Region for the Static Web Apps — a region that offers them. eastus2 in dev, where the existing three are.')
param staticWebAppLocation string = 'eastus2'

@description('Name of the Container Apps environment. ⚠️ Pass the EXISTING one in dev (runbook step 0) or the gateway moves and its FQDN changes.')
param containerEnvName string = 'cae-milestone-command-${env}'

@description('Image tag every service and job starts on. The pipeline moves apps to :<sha> on each push; this is the tag a fresh deployment or a rollback to "whatever main is" uses.')
param imageTag string = 'main'

@description('Entra tenant the services pin issuer-uri to (AZURE_TENANT_ID). The one value that makes the platform single-tenant — tenancy.md.')
param entraTenantId string

@secure()
@description('Flexible Server administrator password — from the vault via getSecret() in the bicepparam, never typed')
param postgresAdminPassword string

@description('Entra user who may administer Postgres without the password (object id). Empty skips it.')
param postgresEntraAdminObjectId string = ''

@description('That user\'s sign-in name')
param postgresEntraAdminLogin string = ''

// ---- what stage 1 created, by the names it computes ----------------
// Same expressions as foundation.bicep and its modules, so nothing has
// to be copied from one deployment's outputs into another's parameters.

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: 'id-mc-apps-${env}'
}

resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: 'acrmilestonecommand${env}'
}

resource vault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: 'kv-mc-milestone-${env}'
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: 'log-milestone-command-${env}'
}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' existing = {
  name: 'ag-mc-${env}-ops'
}

var acr = registry.properties.loginServer
var secretUrl = '${vault.properties.vaultUri}secrets/'
var isProd = env == 'prod'

// Every service runs the `azure` profile: Eureka off, Container Apps DNS
// is the registry. And every service pins the one tenant.
var commonEnv = [
  { name: 'SPRING_PROFILES_ACTIVE', value: 'azure' }
  { name: 'AZURE_TENANT_ID', value: entraTenantId }
]

// ---- data -------------------------------------------------------------

module postgres 'modules/postgres.bicep' = {
  name: 'postgres'
  params: {
    env: env
    location: location
    adminPassword: postgresAdminPassword
    entraAdminObjectId: postgresEntraAdminObjectId
    entraAdminLogin: postgresEntraAdminLogin
  }
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    env: env
    location: location
    keyVaultName: vault.name
  }
}

// One JDBC URL shape for every service. sslmode=require because the
// server enforces TLS; without it the driver negotiates plaintext first
// and the connection is refused with a message that does not say why.
func jdbc(host string, db string) string => 'jdbc:postgresql://${host}:5432/${db}?sslmode=require'

// ---- compute ----------------------------------------------------------

module containerEnv 'modules/container-env.bicep' = {
  name: 'container-env'
  params: {
    env: env
    location: location
    name: containerEnvName
    workspaceId: workspace.id
  }
}

// Connection arithmetic, because B1ms allows 50 connections in total:
//   milestone  2 replicas × 6  = 12
//   identity   2 replicas × 4  =  8
//   template   2 replicas × 4  =  8
//   jobs, admin, the sweeper's ShedLock              ~ 6
//                                                    ---
//                                                     34  < 50
// Hikari's default is 10 per replica, which alone would exceed the
// server at three replicas of one service. SPRING_DATASOURCE_HIKARI_*
// is Spring's relaxed binding of the property; no code change.

// ---- front ends ----------------------------------------------------------

var webApps = ['shell', 'dashboards', 'templates', 'field']

module swa 'modules/static-web-app.bicep' = [for app in webApps: {
  name: 'stapp-${app}'
  params: {
    app: app
    env: env
    location: staticWebAppLocation
    sku: isProd ? 'Standard' : 'Free'
  }
}]

// Sprint 24 security review: the gateway's CORS origins are exact in the
// cloud — these four sites and the two origins a Capacitor webview
// presents (https://localhost on Android, capacitor://localhost on iOS) —
// rather than the default profile's every-site-in-Azure pattern.
// Spelled out rather than looped: a for-body in a variable may not read a
// module output (BCP182), and four names are four names.
var corsAllowedOrigins = join([
  'https://${swa[0].outputs.defaultHostname}'
  'https://${swa[1].outputs.defaultHostname}'
  'https://${swa[2].outputs.defaultHostname}'
  'https://${swa[3].outputs.defaultHostname}'
  'https://localhost'
  'capacitor://localhost'
], ',')

module gateway 'modules/container-app.bicep' = {
  name: 'ca-api-gateway'
  params: {
    name: 'ca-api-gateway'
    location: location
    environmentId: containerEnv.outputs.id
    identityId: identity.id
    registryServer: acr
    image: '${acr}/mc-api-gateway:${imageTag}'
    port: 8080
    external: true
    // The front door must answer; a cold JVM is a 30-second outage.
    minReplicas: 1
    maxReplicas: isProd ? 4 : 2
    envVars: concat(commonEnv, [
      { name: 'MILESTONE_SERVICE_URI', value: 'http://ca-milestone-service' }
      { name: 'IDENTITY_SERVICE_URI', value: 'http://ca-identity-service' }
      { name: 'TEMPLATE_SERVICE_URI', value: 'http://ca-template-service' }
      { name: 'INTEGRATION_SERVICE_URI', value: 'http://ca-integration-service' }
      { name: 'CORS_ALLOWED_ORIGINS', value: corsAllowedOrigins }
    ])
  }
}

module milestone 'modules/container-app.bicep' = {
  name: 'ca-milestone-service'
  params: {
    name: 'ca-milestone-service'
    location: location
    environmentId: containerEnv.outputs.id
    identityId: identity.id
    registryServer: acr
    image: '${acr}/mc-milestone-service:${imageTag}'
    port: 8081
    // The hourly status sweeper needs a live process (backend §12).
    minReplicas: 1
    maxReplicas: 2
    envVars: concat(commonEnv, [
      { name: 'DB_URL', value: jdbc(postgres.outputs.fqdn, 'milestone_db') }
      { name: 'DB_USER', value: 'milestone_svc' }
      { name: 'DB_POOL_MAX', value: '6' }
      { name: 'EVIDENCE_CONTAINER', value: storage.outputs.containerName }
    ])
    secrets: [
      { name: 'db-password', envName: 'DB_PASSWORD', keyVaultUrl: '${secretUrl}pg-milestone-svc-password' }
      { name: 'evidence-connection-string', envName: 'EVIDENCE_STORAGE_CONNECTION_STRING', keyVaultUrl: '${secretUrl}evidence-connection-string' }
    ]
  }
}

module identitySvc 'modules/container-app.bicep' = {
  name: 'ca-identity-service'
  params: {
    name: 'ca-identity-service'
    location: location
    environmentId: containerEnv.outputs.id
    identityId: identity.id
    registryServer: acr
    image: '${acr}/mc-identity-service:${imageTag}'
    port: 8083
    // Names are an enhancement, not a prerequisite (compose.yml): a cold
    // start here costs a row without attribution for thirty seconds.
    minReplicas: 0
    maxReplicas: 2
    envVars: concat(commonEnv, [
      { name: 'DB_URL', value: jdbc(postgres.outputs.fqdn, 'identity_db') }
      { name: 'DB_USER', value: 'identity_svc' }
      { name: 'SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE', value: '4' }
    ])
    secrets: [
      { name: 'db-password', envName: 'DB_PASSWORD', keyVaultUrl: '${secretUrl}pg-identity-svc-password' }
    ]
  }
}

module template 'modules/container-app.bicep' = {
  name: 'ca-template-service'
  params: {
    name: 'ca-template-service'
    location: location
    environmentId: containerEnv.outputs.id
    identityId: identity.id
    registryServer: acr
    image: '${acr}/mc-template-service:${imageTag}'
    port: 8084
    minReplicas: 0
    maxReplicas: 2
    envVars: concat(commonEnv, [
      { name: 'DB_URL', value: jdbc(postgres.outputs.fqdn, 'template_db') }
      { name: 'DB_USER', value: 'template_svc' }
      { name: 'SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE', value: '4' }
    ])
    secrets: [
      { name: 'db-password', envName: 'DB_PASSWORD', keyVaultUrl: '${secretUrl}pg-template-svc-password' }
    ]
  }
}

module integration 'modules/container-app.bicep' = {
  name: 'ca-integration-service'
  params: {
    name: 'ca-integration-service'
    location: location
    environmentId: containerEnv.outputs.id
    identityId: identity.id
    registryServer: acr
    image: '${acr}/mc-integration-service:${imageTag}'
    port: 8085
    // No database, no state: parses a file and answers. Scale to zero.
    minReplicas: 0
    maxReplicas: 2
    envVars: commonEnv
  }
}

// ---- jobs: migrate, then deploy ----------------------------------------
// The migration image is <service>-migrate: Flyway's own image with the
// service's src/main/resources/db/migration copied in, built and pushed
// by java-service.yml next to the service image, same tag. Same
// migrations, same order, no JDK — the shape compose.yml uses locally,
// minus the bind mount.

var migrations = [
  { service: 'milestone', db: 'milestone_db', user: 'milestone_svc', image: 'mc-milestone-service-migrate' }
  { service: 'identity', db: 'identity_db', user: 'identity_svc', image: 'mc-identity-service-migrate' }
  { service: 'template', db: 'template_db', user: 'template_svc', image: 'mc-template-service-migrate' }
]

module migrate 'modules/job.bicep' = [for m in migrations: {
  name: 'job-migrate-${m.service}'
  params: {
    name: 'job-migrate-${m.service}'
    location: location
    environmentId: containerEnv.outputs.id
    identityId: identity.id
    registryServer: acr
    image: '${acr}/${m.image}:${imageTag}'
    args: ['migrate']
    envVars: [
      { name: 'FLYWAY_URL', value: jdbc(postgres.outputs.fqdn, m.db) }
      { name: 'FLYWAY_USER', value: m.user }
      { name: 'FLYWAY_LOCATIONS', value: 'filesystem:/flyway/sql' }
      { name: 'FLYWAY_CONNECT_RETRIES', value: '10' }
    ]
    secrets: [
      { name: 'db-password', envName: 'FLYWAY_PASSWORD', keyVaultUrl: '${secretUrl}pg-${m.service}-svc-password' }
    ]
  }
}]

// The per-service logins and grants — init/01-databases.sql for the
// cloud, with the passwords from the vault. Idempotent: CREATE only if
// the role is missing, ALTER always, so re-running it after changing a
// vault secret IS the password rotation (runbook §4).
var bootstrapScript = '''
set -eu
ensure() {
  role="$1"; db="$2"; pw="$3"
  psql -v ON_ERROR_STOP=1 -d postgres -v r="$role" -v p="$pw" <<EOSQL
SELECT format('CREATE ROLE %I LOGIN PASSWORD %L', :'r', :'p')
  WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = :'r')
\gexec
SELECT format('ALTER ROLE %I WITH LOGIN PASSWORD %L', :'r', :'p')
\gexec
GRANT ALL PRIVILEGES ON DATABASE $db TO $role;
EOSQL
  psql -v ON_ERROR_STOP=1 -d "$db" \
    -c "REVOKE ALL ON SCHEMA public FROM PUBLIC" \
    -c "GRANT ALL ON SCHEMA public TO $role"
  echo "ok $role -> $db"
}
ensure milestone_svc milestone_db "$MILESTONE_SVC_PASSWORD"
ensure identity_svc  identity_db  "$IDENTITY_SVC_PASSWORD"
ensure template_svc  template_db  "$TEMPLATE_SVC_PASSWORD"
echo "bootstrap complete"
'''

module bootstrapDb 'modules/job.bicep' = {
  name: 'job-bootstrap-db'
  params: {
    name: 'job-bootstrap-db'
    location: location
    environmentId: containerEnv.outputs.id
    identityId: identity.id
    image: 'docker.io/library/postgres:17-alpine'
    command: ['/bin/sh', '-c', bootstrapScript]
    envVars: [
      { name: 'PGHOST', value: postgres.outputs.fqdn }
      { name: 'PGUSER', value: postgres.outputs.adminLogin }
      { name: 'PGDATABASE', value: 'postgres' }
      { name: 'PGSSLMODE', value: 'require' }
    ]
    secrets: [
      { name: 'pg-admin-password', envName: 'PGPASSWORD', keyVaultUrl: '${secretUrl}pg-admin-password' }
      { name: 'pg-milestone-svc-password', envName: 'MILESTONE_SVC_PASSWORD', keyVaultUrl: '${secretUrl}pg-milestone-svc-password' }
      { name: 'pg-identity-svc-password', envName: 'IDENTITY_SVC_PASSWORD', keyVaultUrl: '${secretUrl}pg-identity-svc-password' }
      { name: 'pg-template-svc-password', envName: 'TEMPLATE_SVC_PASSWORD', keyVaultUrl: '${secretUrl}pg-template-svc-password' }
    ]
    timeoutSeconds: 300
  }
}

// ---- alerts ----------------------------------------------------------------

module alerts 'modules/alerts.bicep' = {
  name: 'alerts'
  params: {
    env: env
    actionGroupId: actionGroup.id
    gatewayId: gateway.outputs.id
    postgresId: resourceId('Microsoft.DBforPostgreSQL/flexibleServers', postgres.outputs.serverName)
    apps: [
      { name: gateway.outputs.name, id: gateway.outputs.id }
      { name: milestone.outputs.name, id: milestone.outputs.id }
      { name: identitySvc.outputs.name, id: identitySvc.outputs.id }
      { name: template.outputs.name, id: template.outputs.id }
      { name: integration.outputs.name, id: integration.outputs.id }
    ]
  }
}

// ---- what a person needs afterwards -------------------------------------

output gatewayUrl string = 'https://${gateway.outputs.fqdn}'
output containerEnvDefaultDomain string = containerEnv.outputs.defaultDomain
output postgresFqdn string = postgres.outputs.fqdn
output evidenceAccount string = storage.outputs.accountName
output staticWebApps array = [for (app, i) in webApps: {
  app: app
  name: swa[i].outputs.name
  url: 'https://${swa[i].outputs.defaultHostname}'
}]
output firstRunOrder array = [
  'az containerapp job start -n job-bootstrap-db'
  'az containerapp job start -n job-migrate-milestone'
  'az containerapp job start -n job-migrate-identity'
  'az containerapp job start -n job-migrate-template'
  'the five services restart on their own until the schema exists'
]
