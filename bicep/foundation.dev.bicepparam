// dev — stage 1. Nothing here is a secret: identifiers only (README,
// "Secrets and how they are stored").
using 'foundation.bicep'

param env = 'dev'
param location = 'francecentral'
param opsEmail = 'rachidouahmanetdi@gmail.com'

// Whoever runs the deployment. From the personal CLI profile:
//   az ad signed-in-user show --query id -o tsv
// Read from the environment rather than written here so the file is the
// same for a person and for the pipeline identity.
param deployerPrincipalId = readEnvironmentVariable('MC_DEPLOYER_OBJECT_ID')

// The GitHub deploy identity's service principal — the object id, not the
// app id (a role assignment names the principal). Sprint 24: it reads the
// automation secret to run the load test.
//   az ad sp show --id (gh variable get AZURE_CLIENT_ID -R rachidpeaqock/mc-platform-infra) --query id -o tsv
param ciPrincipalId = 'db248ab7-5e95-46a6-ae1f-2989ff761f99'
