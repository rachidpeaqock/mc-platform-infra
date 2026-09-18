// ============================================================
// PostgreSQL Flexible Server — one server, one database per service
// ============================================================
// platform-architecture.md §6: one login per service, no cross-database
// grants, so a service that could reach another's data cannot. The
// databases are declared here; the logins and grants are SQL, which ARM
// cannot run, so they are created by the bootstrap job
// (bootstrap-db-job.bicep) with passwords read from Key Vault. Locally
// init/01-databases.sql does the same thing with fixed passwords.
//
// Not declared: activity_db. activity-service is parked against its
// trigger (sprint-plan.md, E5), and an empty database bills for storage
// and appears in every backup.

@description('Environment discriminator: dev, prod')
param env string

param location string

@description('Administrator login name — used only by the bootstrap job and the restore drill')
param adminLogin string = 'mcadmin'

@secure()
@description('Administrator password. Generated once by the runbook, held in Key Vault as pg-admin-password, passed in by the bicepparam via getSecret()')
param adminPassword string

@description('Object id of the Entra user who may administer the server without the password. Empty skips it.')
param entraAdminObjectId string = ''

@description('Sign-in name (UPN) of that user, shown as the role name in Postgres')
param entraAdminLogin string = ''

@description('The service databases. Each gets a login of the same stem with _svc, created by the bootstrap job.')
param databases array = [
  'milestone_db'
  'identity_db'
  'template_db'
]

var isProd = env == 'prod'

resource server 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: 'psql-milestone-command-${env}'
  location: location
  sku: {
    // B1ms in dev: one burstable vCPU, 2 GiB, the cheapest server that
    // exists. B2s for prod per azure-deployment-plan.md §10 — the sweeper
    // and five connection pools want a second core.
    name: isProd ? 'Standard_B2s' : 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    version: '17'
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
    storage: {
      storageSizeGB: 32
      autoGrow: 'Enabled'
    }
    backup: {
      // Point-in-time restore inside this window is the restore drill.
      backupRetentionDays: isProd ? 14 : 7
      geoRedundantBackup: isProd ? 'Enabled' : 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    authConfig: {
      // Password auth stays on: the services connect with JDBC and a
      // password from Key Vault. Entra auth is for people.
      passwordAuth: 'Enabled'
      activeDirectoryAuth: empty(entraAdminObjectId) ? 'Disabled' : 'Enabled'
      tenantId: empty(entraAdminObjectId) ? null : tenant().tenantId
    }
    network: {
      // Public endpoint with a firewall, not a VNet: Container Apps on the
      // consumption plan have no fixed egress and a VNet-integrated
      // environment is a different (and billed) topology. TLS is
      // enforced by the server; the JDBC URLs carry sslmode=require.
      // Moving to private networking is the runbook's hardening list.
      publicNetworkAccess: 'Enabled'
    }
  }
}

// 0.0.0.0–0.0.0.0 is Azure's magic range for "any Azure service in any
// subscription" — broad, and the accepted shape for a public Flexible
// Server reached from consumption Container Apps. Every connection still
// needs a login this server knows.
resource allowAzure 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2024-08-01' = {
  parent: server
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource entraAdmin 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2024-08-01' = if (!empty(entraAdminObjectId)) {
  parent: server
  name: entraAdminObjectId
  properties: {
    principalType: 'User'
    principalName: entraAdminLogin
    tenantId: tenant().tenantId
  }
  dependsOn: [allowAzure]
}

@batchSize(1)
resource db 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = [for name in databases: {
  parent: server
  name: name
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
  dependsOn: [allowAzure]
}]

output serverName string = server.name
output fqdn string = server.properties.fullyQualifiedDomainName
output adminLogin string = adminLogin
output databases array = databases
