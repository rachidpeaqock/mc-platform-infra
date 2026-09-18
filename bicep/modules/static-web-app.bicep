// ============================================================
// One Angular front end on Static Web Apps
// ============================================================
// Three exist already — stapp-mc-{shell,dashboards,templates}-dev in
// eastus2, created by hand in Sprints 2–3 and deployed to on every push
// by angular-app.yml with a per-site token. Declaring them here adopts
// them and keeps their hostnames (the *.azurestaticapps.net names every
// cross-app link is built with — platform-apps.ts). The fourth, Field,
// is new: its token is the last H4 item angular-app.yml is waiting on.
//
// Static Web Apps is not offered in France Central, hence a region of
// its own (README, "regions are inconsistent because Azure forced it").

@description('App short name: shell, dashboards, templates, field')
param app string

@description('Environment discriminator: dev, prod')
param env string

@description('A region that offers Static Web Apps. eastus2 in dev, because that is where the existing three are.')
param location string

@description('Free in dev. Standard buys a custom domain with managed TLS, more staging environments, and an SLA — prod.')
@allowed(['Free', 'Standard'])
param sku string = 'Free'

resource site 'Microsoft.Web/staticSites@2023-12-01' = {
  name: 'stapp-mc-${app}-${env}'
  location: location
  sku: {
    name: sku
    tier: sku
  }
  properties: {
    // The pipeline builds and uploads; Azure never sees the repo. That is
    // what lets angular-app.yml verify the bundle before it deploys it.
    buildProperties: {
      skipGithubActionWorkflowGeneration: true
    }
    // PR preview environments. The token also grants these; the
    // pipeline tears them down on close.
    stagingEnvironmentPolicy: 'Enabled'
    allowConfigFileUpdates: true
  }
}

output name string = site.name
output defaultHostname string = site.properties.defaultHostname
