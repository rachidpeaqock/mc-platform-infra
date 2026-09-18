// ============================================================
// Alerts — the estate tells someone, rather than someone noticing
// ============================================================
// Each alert names the thing a person would otherwise find out from a
// user. Thresholds are for pilot load (~50 people, five services) and
// are parameters so prod can tighten them without editing the rule.
//
// Not here: outbox lag. There is no outbox — activity-service is parked
// (E5). When it is built, its alert lands in this file with it.
// Not here either: the budget. Consumption budgets are subscription
// scope; see ../budget.bicep.

@description('Environment discriminator: dev, prod')
param env string

@description('Action group every alert fires into')
param actionGroupId string

@description('The five apps as [{ name, id }]')
param apps array

@description('The gateway\'s resource id — the one app whose 5xx a user sees')
param gatewayId string

@description('Flexible Server resource id')
param postgresId string

@description('5xx responses at the gateway in five minutes before someone hears')
param gateway5xxThreshold int = 20

@description('Container restarts in fifteen minutes before someone hears — a crash loop is 3 in the first minute')
param restartThreshold int = 3

var actions = [
  {
    actionGroupId: actionGroupId
  }
]

// ---- The gateway is answering 5xx: the platform is failing in front of users
resource gateway5xx 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-mc-${env}-gateway-5xx'
  location: 'global'
  properties: {
    description: 'ca-api-gateway returned ${gateway5xxThreshold}+ 5xx responses in 5 minutes. A service behind it is down or the breaker is open (fallback answers 503 on purpose — see GatewayRoutingTest).'
    severity: 1
    enabled: true
    scopes: [gatewayId]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    targetResourceType: 'Microsoft.App/containerApps'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'server-errors'
          metricNamespace: 'Microsoft.App/containerApps'
          metricName: 'Requests'
          dimensions: [
            {
              name: 'statusCodeCategory'
              operator: 'Include'
              values: ['5xx']
            }
          ]
          operator: 'GreaterThan'
          threshold: gateway5xxThreshold
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: actions
  }
}

// ---- A container is crash-looping: SchemaVersionGuard, a bad secret, OOM
resource restarts 'Microsoft.Insights/metricAlerts@2018-03-01' = [for app in apps: {
  name: 'alert-mc-${env}-${app.name}-restarts'
  location: 'global'
  properties: {
    description: '${app.name} restarted ${restartThreshold}+ times in 15 minutes. First look: `az containerapp logs show -n ${app.name} --type system`. An un-migrated database fails startup on purpose (MC-304) and looks exactly like this.'
    severity: 1
    enabled: true
    scopes: [app.id]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    targetResourceType: 'Microsoft.App/containerApps'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'restarts'
          metricNamespace: 'Microsoft.App/containerApps'
          metricName: 'RestartCount'
          operator: 'GreaterThanOrEqual'
          threshold: restartThreshold
          timeAggregation: 'Maximum'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: actions
  }
}]

// ---- The database: the one resource whose failure takes everything with it
resource postgresDown 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-mc-${env}-postgres-down'
  location: 'global'
  properties: {
    description: 'psql-milestone-command-${env} is not answering. Every service\'s readiness probe will fail and the gateway will answer 503 — this alert fires first.'
    severity: 0
    enabled: true
    scopes: [postgresId]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    targetResourceType: 'Microsoft.DBforPostgreSQL/flexibleServers'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'alive'
          metricNamespace: 'Microsoft.DBforPostgreSQL/flexibleServers'
          metricName: 'is_db_alive'
          operator: 'LessThan'
          threshold: 1
          timeAggregation: 'Minimum'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: actions
  }
}

resource postgresStorage 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-mc-${env}-postgres-storage'
  location: 'global'
  properties: {
    description: 'Storage above 80 %. autoGrow is on, so this is a cost signal, not an outage — but the audit table is append-only by design and only grows.'
    severity: 3
    enabled: true
    scopes: [postgresId]
    evaluationFrequency: 'PT15M'
    windowSize: 'PT1H'
    targetResourceType: 'Microsoft.DBforPostgreSQL/flexibleServers'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'storage'
          metricNamespace: 'Microsoft.DBforPostgreSQL/flexibleServers'
          metricName: 'storage_percent'
          operator: 'GreaterThan'
          threshold: 80
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: actions
  }
}

resource postgresCpu 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-mc-${env}-postgres-cpu'
  location: 'global'
  properties: {
    description: 'CPU above 80 % for 15 minutes on a burstable SKU: credits are draining and queries will slow before anything fails. The k6 run (Sprint 24) is meant to trip this on purpose once.'
    severity: 2
    enabled: true
    scopes: [postgresId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    targetResourceType: 'Microsoft.DBforPostgreSQL/flexibleServers'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'cpu'
          metricNamespace: 'Microsoft.DBforPostgreSQL/flexibleServers'
          metricName: 'cpu_percent'
          operator: 'GreaterThan'
          threshold: 80
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: actions
  }
}
