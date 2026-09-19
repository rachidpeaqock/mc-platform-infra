// ============================================================
// Monitoring — one Log Analytics workspace, one App Insights, one
// action group. Everything else in the estate writes here.
// ============================================================
// These two already exist in the dev group, created by hand in Sprint 2
// (log-milestone-command-dev, appi-milestone-command-dev). Declaring them
// under the same names adopts them: ARM PUTs the properties below over
// what is there, and the workspace keeps its data.

@description('Environment discriminator: dev, prod')
param env string

@description('Region for the workspace and the component')
param location string

@description('Where alerts go. One address for now; the runbook says how to add a second.')
param opsEmail string

@description('Days of log retention. 30 is the free-tier ceiling; prod raises it.')
param retentionDays int = 30

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-milestone-command-${env}'
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: retentionDays
    workspaceCapping: {
      // Free-trial safety: a runaway log loop cannot spend the credit.
      // 1 GB/day is far above what five services at pilot load produce.
      dailyQuotaGb: 1
    }
  }
}

resource insights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-milestone-command-${env}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
    IngestionMode: 'LogAnalytics'
    // 90 days is the free allowance and what the hand-made component has; never shorten it.
    RetentionInDays: 90
  }
}

// The people an alert wakes. Alerts reference this by id; adding a
// channel (Teams webhook, SMS) is one entry here and nothing elsewhere.
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-mc-${env}-ops'
  location: 'global'
  properties: {
    groupShortName: 'mc-${env}'
    enabled: true
    emailReceivers: [
      {
        name: 'ops'
        emailAddress: opsEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

output workspaceId string = workspace.id
output workspaceCustomerId string = workspace.properties.customerId
output insightsId string = insights.id
output actionGroupId string = actionGroup.id
