// dev — stage 2. Identifiers only; the one secret is fetched from the
// vault at deploy time by whoever runs this, never written down.
using 'platform.bicep'

param env = 'dev'
param location = 'francecentral'
param staticWebAppLocation = 'eastus2'

// ⚠️ Runbook step 0. The environment ca-api-gateway already lives in was
// created by hand and its name was not recorded. Find it:
//   az containerapp env list -g rg-milestone-command-dev --query "[].name" -o tsv
// and put it here. Leaving the default creates a second environment and
// moves the gateway to a new FQDN — every front end's api-config.ts
// carries the current one.
param containerEnvName = readEnvironmentVariable('MC_CONTAINER_ENV_NAME', 'cae-milestone-command-dev')

param imageTag = 'main'

// The tenant every service pins issuer-uri to. An identifier, in every
// token; also the default in each application.yml.
param entraTenantId = '5b6fa978-e0da-4f01-bb84-37309bc3fe60'

// The administrator password, read out of the vault by the deployer's own
// identity as the deployment is submitted. Requires the bootstrap step
// (runbook §1) to have run once. Subscription id is an identifier.
param postgresAdminPassword = az.getSecret(
  'f5dd2845-c223-47a4-9539-724ad720e327',
  'rg-milestone-command-dev',
  'kv-mc-milestone-dev',
  'pg-admin-password'
)

// Optional: administer Postgres as yourself, without the password.
//   az ad signed-in-user show --query "{id:id, upn:userPrincipalName}" -o tsv
param postgresEntraAdminObjectId = readEnvironmentVariable('MC_DEPLOYER_OBJECT_ID', '')
param postgresEntraAdminLogin = readEnvironmentVariable('MC_DEPLOYER_UPN', '')
