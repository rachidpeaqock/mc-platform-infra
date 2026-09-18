// ============================================================
// Container Apps environment — the network the five services share
// ============================================================
// Every app in the environment gets an internal DNS name equal to its
// app name, which is the service discovery the platform uses in the
// cloud (the gateway's `azure` profile names http://ca-milestone-service
// and so on; Eureka stays in compose, where it does real work).
//
// ⚠️ One environment already exists in the dev group, created by hand,
// with ca-api-gateway inside it. Its NAME is not recorded anywhere — only
// its default domain (wittysmoke-6cd637b5.francecentral) shows in the
// gateway URL the front ends are built with. Pass that name as `name`
// and this module adopts it. Let it default and Bicep creates a second
// environment, the gateway moves, its FQDN changes, and every front end
// needs its api-config changed. The runbook's step 0 is finding the name.

@description('Environment discriminator: dev, prod')
param env string

param location string

@description('Name of the managed environment. Pass the existing one to adopt it.')
param name string = 'cae-milestone-command-${env}'

@description('Log Analytics workspace the containers\' console output is shipped to')
param workspaceId string

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: last(split(workspaceId, '/'))
}

resource environment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: name
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: workspace.properties.customerId
        sharedKey: workspace.listKeys().primarySharedKey
      }
    }
    // Consumption only. A dedicated workload profile is a fixed monthly
    // charge for capacity nothing here needs yet.
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
    zoneRedundant: false
  }
}

output id string = environment.id
output name string = environment.name
output defaultDomain string = environment.properties.defaultDomain
