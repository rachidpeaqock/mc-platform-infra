// ============================================================
// Budget — the one alert that fires on money, not on failure
// ============================================================
// Subscription scope, which is why it is not inside platform.bicep: a
// Consumption budget filtered to the resource group has to be created at
// the subscription, and a resource-group deployment cannot do that.
//
//   az deployment sub create -l francecentral \
//     -f bicep/budget.bicep -p env=dev opsEmail=… startDate=2026-10-01
//
// On the free trial the spending limit already stops billing dead; this
// is the warning BEFORE that happens, because the limit stopping billing
// also stops the gateway. On a pay-as-you-go subscription it is the only
// thing between a misconfigured scale rule and an invoice.

targetScope = 'subscription'

@description('Environment discriminator: dev, prod')
param env string

@description('Monthly amount in the subscription\'s billing currency. azure-deployment-plan.md §11 puts the pilot at ~€35–50; 60 leaves headroom without hiding a doubling.')
param amount int = 60

@description('First day of the month the budget starts, YYYY-MM-01')
param startDate string

@description('Who hears at 80 % and at 100 %')
param opsEmail string

resource budget 'Microsoft.Consumption/budgets@2023-11-01' = {
  name: 'budget-mc-${env}'
  properties: {
    category: 'Cost'
    amount: amount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
    }
    filter: {
      dimensions: {
        name: 'ResourceGroupName'
        operator: 'In'
        values: ['rg-milestone-command-${env}']
      }
    }
    notifications: {
      actual80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        thresholdType: 'Actual'
        contactEmails: [opsEmail]
      }
      forecast100: {
        // Forecast, not actual: the point is to hear on the 12th that the
        // month will end over, not on the 28th that it did.
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        thresholdType: 'Forecasted'
        contactEmails: [opsEmail]
      }
    }
  }
}
