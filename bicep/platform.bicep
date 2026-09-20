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

// An app's address inside the environment, through its internal ingress.
func internalUrlIn(app string, envDomain string) string => 'https://${app}.internal.${envDomain}'

// ---- live sync (Sprint 14, second half) ----------------------------------

module webpubsub 'modules/webpubsub.bicep' = {
  name: 'webpubsub'
  params: {
    env: env
    location: location
    publisherPrincipalId: identity.properties.principalId
    actionGroupId: actionGroup.id
  }
}

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

var envDomain = containerEnv.outputs.defaultDomain

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
    // The internal-ingress FQDN form, https://<app>.internal.<env domain>:
    // it is what the hand-built gateway has routed with since 2026-08-24,
    // so it is the form known to work. The bare app name would resolve
    // too, but "would" is not "does".
    envVars: concat(commonEnv, [
      { name: 'MILESTONE_SERVICE_URI', value: internalUrlIn('ca-milestone-service', envDomain) }
      { name: 'IDENTITY_SERVICE_URI', value: internalUrlIn('ca-identity-service', envDomain) }
      { name: 'TEMPLATE_SERVICE_URI', value: internalUrlIn('ca-template-service', envDomain) }
      { name: 'INTEGRATION_SERVICE_URI', value: internalUrlIn('ca-integration-service', envDomain) }
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
      // Live sync. The relay and the token endpoint authenticate to Web
      // PubSub with the app's own identity; the client id tells the Azure
      // SDK which of the environment's identities to use.
      { name: 'REALTIME_ENDPOINT', value: webpubsub.outputs.endpoint }
      { name: 'REALTIME_HUB', value: webpubsub.outputs.hub }
      { name: 'AZURE_CLIENT_ID', value: identity.properties.clientId }
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
    // Found in the first walkthrough (2026-09-19): a planner's save waited
    // out a 40 s JVM cold start and the gateway answered 504 at 30. The
    // two services a planner uses interactively keep one replica warm;
    // ~€10/month each is cheaper than the first impression.
    minReplicas: 1
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
    // No database, no state — but a planner is waiting on the other side
    // of the upload, so one replica stays warm (see template-service).
    minReplicas: 1
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
      // The hand-built caj-migrate applied a V900 dev seed to milestone_db
      // ahead of V7–V12, so Flyway's validate sees those as out of order
      // and refuses. They are genuinely pending. Allowing out-of-order
      // costs nothing on the other two databases, which the templates
      // created empty, and it is what makes the adopted one migratable.
      { name: 'FLYWAY_OUT_OF_ORDER', value: 'true' }
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
  # The hand-built milestone-service migrated as the administrator, so
  # milestone_db's tables (flyway_schema_history included) are owned by
  # mcadmin, and a Flyway run as milestone_svc would fail on the first
  # ALTER. Hand what the administrator owns in this database to the
  # service's login: GRANT the role to ourselves so REASSIGN is allowed,
  # reassign, and the database itself with it. A no-op on a fresh one.
  # Order matters, and the first run got it wrong: a table's new owner
  # must already hold CREATE on its schema, or REASSIGN answers
  # "permission denied for schema public". Schema grant first.
  psql -v ON_ERROR_STOP=1 -d "$db" \
    -c "REVOKE ALL ON SCHEMA public FROM PUBLIC" \
    -c "GRANT ALL ON SCHEMA public TO $role" \
    -c "GRANT $role TO CURRENT_USER" \
    -c "REASSIGN OWNED BY CURRENT_USER TO $role" \
    -c "ALTER DATABASE $db OWNER TO $role"
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

// Sprint 24 — the load fixture. load/seed-5000.sql, verbatim, run as the
// service's own login (it owns the tables) by a one-off job: the same
// shape as job-bootstrap-db, because port 5432 is unreachable from the
// development machine and a GitHub runner is not promised a path either.
// Started by load.yml, or by hand:
//   az containerapp job start -n job-seed-load -g rg-milestone-command-dev
// Idempotent — the script deletes and recreates LOAD-5K — and dev-only by
// intent: it is a fixture, and the audit rows k6 writes on it are noise.
var seedSql = loadTextContent('../load/seed-5000.sql')

module seedLoad 'modules/job.bicep' = {
  name: 'job-seed-load'
  params: {
    name: 'job-seed-load'
    location: location
    environmentId: containerEnv.outputs.id
    identityId: identity.id
    image: 'docker.io/library/postgres:17-alpine'
    // -c with several statements runs them as sent; the script's own
    // BEGIN/COMMIT bound the transaction and the final SELECT is what
    // the log shows: "milestones | 5000".
    command: ['psql', '-v', 'ON_ERROR_STOP=1', '-c', seedSql]
    envVars: [
      { name: 'PGHOST', value: postgres.outputs.fqdn }
      { name: 'PGUSER', value: 'milestone_svc' }
      { name: 'PGDATABASE', value: 'milestone_db' }
      { name: 'PGSSLMODE', value: 'require' }
    ]
    secrets: [
      { name: 'pg-milestone-svc-password', envName: 'PGPASSWORD', keyVaultUrl: '${secretUrl}pg-milestone-svc-password' }
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
output realtimeEndpoint string = webpubsub.outputs.endpoint
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
