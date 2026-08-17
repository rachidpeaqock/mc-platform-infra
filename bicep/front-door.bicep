// ============================================================
// Front Door — one origin for three separately deployed apps
// ============================================================
// The three web apps ship on their own cadences from their own repos,
// but users and MSAL must see a single origin: one token domain, no CORS
// between apps, and one place for TLS and WAF.
//
// Routing is by path prefix:
//   /                → mc-shell        (launcher)
//   /dashboards/*    → mc-dashboards
//   /templates/*     → mc-templates
//   /api/*           → api-gateway     (added in Sprint 4)
//
// Field is absent on purpose: it is a native iOS/Android app and reaches
// /api directly, never through the web origin.
//
// NOT YET DEPLOYED — needs the Azure subscription (MC-002, Sprint 4).
// It is written now so the routing contract is fixed before three apps
// start assuming their own origins.

@description('Environment discriminator, e.g. dev or prod')
param env string

@description('Azure region for the profile metadata')
param location string = 'global'

@description('Static Web App default hostnames, in deployment order')
param shellHostname string
param dashboardsHostname string
param templatesHostname string

var profileName = 'mc-${env}-fd'
var endpointName = 'mc-${env}-endpoint'

resource profile 'Microsoft.Cdn/profiles@2024-02-01' = {
  name: profileName
  location: location
  sku: {
    // Standard covers path routing, custom domains and managed TLS.
    // Premium adds managed WAF rules — worth revisiting before the app
    // is reachable from the public internet with real project data.
    name: 'Standard_AzureFrontDoor'
  }
}

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2024-02-01' = {
  parent: profile
  name: endpointName
  location: location
  properties: {
    enabledState: 'Enabled'
  }
}

// ---- one origin group per app ----------------------------------------
// Separate groups rather than one pooled group: these are different
// applications, not replicas of one, so health and failover are per-app.

resource shellOrigins 'Microsoft.Cdn/profiles/originGroups@2024-02-01' = {
  parent: profile
  name: 'og-shell'
  properties: {
    loadBalancingSettings: { sampleSize: 4, successfulSamplesRequired: 3 }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 100
    }
  }
}

resource shellOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2024-02-01' = {
  parent: shellOrigins
  name: 'origin-shell'
  properties: {
    hostName: shellHostname
    originHostHeader: shellHostname
    httpsPort: 443
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

resource dashboardsOrigins 'Microsoft.Cdn/profiles/originGroups@2024-02-01' = {
  parent: profile
  name: 'og-dashboards'
  properties: {
    loadBalancingSettings: { sampleSize: 4, successfulSamplesRequired: 3 }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 100
    }
  }
}

resource dashboardsOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2024-02-01' = {
  parent: dashboardsOrigins
  name: 'origin-dashboards'
  properties: {
    hostName: dashboardsHostname
    originHostHeader: dashboardsHostname
    httpsPort: 443
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

resource templatesOrigins 'Microsoft.Cdn/profiles/originGroups@2024-02-01' = {
  parent: profile
  name: 'og-templates'
  properties: {
    loadBalancingSettings: { sampleSize: 4, successfulSamplesRequired: 3 }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 100
    }
  }
}

resource templatesOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2024-02-01' = {
  parent: templatesOrigins
  name: 'origin-templates'
  properties: {
    hostName: templatesHostname
    originHostHeader: templatesHostname
    httpsPort: 443
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

// ---- routes ----------------------------------------------------------
// Most specific first. Front Door matches the longest pattern, but the
// ordering is kept explicit so the intent survives future edits.

resource routeDashboards 'Microsoft.Cdn/profiles/afdEndpoints/routes@2024-02-01' = {
  parent: endpoint
  name: 'route-dashboards'
  dependsOn: [dashboardsOrigin]
  properties: {
    originGroup: { id: dashboardsOrigins.id }
    patternsToMatch: ['/dashboards', '/dashboards/*']
    supportedProtocols: ['Https']
    forwardingProtocol: 'HttpsOnly'
    httpsRedirect: 'Enabled'
    linkToDefaultDomain: 'Enabled'
  }
}

resource routeTemplates 'Microsoft.Cdn/profiles/afdEndpoints/routes@2024-02-01' = {
  parent: endpoint
  name: 'route-templates'
  dependsOn: [templatesOrigin, routeDashboards]
  properties: {
    originGroup: { id: templatesOrigins.id }
    patternsToMatch: ['/templates', '/templates/*']
    supportedProtocols: ['Https']
    forwardingProtocol: 'HttpsOnly'
    httpsRedirect: 'Enabled'
    linkToDefaultDomain: 'Enabled'
  }
}

// Catch-all last: anything not claimed by an app is the launcher.
resource routeShell 'Microsoft.Cdn/profiles/afdEndpoints/routes@2024-02-01' = {
  parent: endpoint
  name: 'route-shell'
  dependsOn: [shellOrigin, routeTemplates]
  properties: {
    originGroup: { id: shellOrigins.id }
    patternsToMatch: ['/*']
    supportedProtocols: ['Https']
    forwardingProtocol: 'HttpsOnly'
    httpsRedirect: 'Enabled'
    linkToDefaultDomain: 'Enabled'
  }
}

output endpointHostname string = endpoint.properties.hostName
