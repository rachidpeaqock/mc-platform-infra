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
