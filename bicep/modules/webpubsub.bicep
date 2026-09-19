// ============================================================
// Web PubSub — the channel that tells a board "something changed"
// ============================================================
// Sprint 14, second half (2026-09-19). milestone-service's outbox relay
// sends one small message per change to a group; Dashboards and Field
// hold a socket and, on a message, re-read the truth from the API. The
// message never carries a number — it says what changed, never to what.
//
// Free_F1 in dev: 20 concurrent connections, 20,000 messages a day. A
// pilot of fifty people with a few tabs each fits; the alert below says
// when it stops fitting, and the SKU is one parameter.
//
// The apps authenticate with their managed identity (Web PubSub Service
// Owner), so the vault holds nothing new and no connection string exists.

@description('Environment discriminator: dev, prod')
param env string

param location string

@description('Principal id of the identity milestone-service runs as')
param publisherPrincipalId string

@description('Action group for the ceiling alert')
param actionGroupId string

@description('Free_F1 in dev; Standard_S1 (1,000 connections, 1M messages/day per unit) for a pilot')
@allowed(['Free_F1', 'Standard_S1'])
param sku string = env == 'prod' ? 'Standard_S1' : 'Free_F1'

// Web PubSub Service Owner
var ownerRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '12cf5a90-567b-43ae-8102-96cf46c7d9b4')

resource service 'Microsoft.SignalRService/webPubSub@2024-03-01' = {
  name: 'wps-milestone-command-${env}'
  location: location
  sku: {
    name: sku
    tier: sku == 'Free_F1' ? 'Free' : 'Standard'
    capacity: 1
  }
  identity: {
    type: 'None'
  }
  properties: {
    // Clients bring a token the server minted; nothing connects with a key.
    disableLocalAuth: true
    disableAadAuth: false
    publicNetworkAccess: 'Enabled'
    tls: {
      clientCertEnabled: false
    }
  }
}

// One hub. Groups inside it are per project and per user; the server
// decides which a token may join.
resource hub 'Microsoft.SignalRService/webPubSub/hubs@2024-03-01' = {
  parent: service
  name: 'milestones'
  properties: {
    anonymousConnectPolicy: 'deny'
    eventHandlers: []
  }
}

resource publish 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(service.id, publisherPrincipalId, ownerRoleId)
  scope: service
  properties: {
    roleDefinitionId: ownerRoleId
    principalId: publisherPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// The Free tier's ceiling is a hard one: the 21st connection is refused.
// Hear about it at 16, not from a user.
resource nearCeiling 'Microsoft.Insights/metricAlerts@2018-03-01' = if (sku == 'Free_F1') {
  name: 'alert-mc-${env}-webpubsub-connections'
  location: 'global'
  properties: {
    description: 'Web PubSub is near the Free tier\'s 20 concurrent connections. Move to Standard_S1 (one parameter in webpubsub.bicep) before the 21st board is refused.'
    severity: 2
    enabled: true
    scopes: [service.id]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    targetResourceType: 'Microsoft.SignalRService/webPubSub'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'connections'
          metricNamespace: 'Microsoft.SignalRService/webPubSub'
          metricName: 'TotalConnectionCount'
          operator: 'GreaterThanOrEqual'
          threshold: 16
          timeAggregation: 'Maximum'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [{ actionGroupId: actionGroupId }]
  }
}

output name string = service.name
output endpoint string = 'https://${service.properties.hostName}'
output hub string = hub.name
