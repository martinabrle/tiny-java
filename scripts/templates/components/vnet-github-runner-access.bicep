param runnerPrincipalId string
param runnerName string
param dbServerName string
param appServiceName string

resource postgres 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' existing = {
  name: dbServerName
}

resource app 'Microsoft.Web/sites@2022-03-01' existing = {
  name: appServiceName
}

resource runnerAdmin 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2024-08-01' = {
  parent: postgres
  name: runnerPrincipalId
  properties: {
    principalName: runnerName
    principalType: 'ServicePrincipal'
    tenantId: subscription().tenantId
  }
}

var websiteContributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'de139f84-1756-47ae-9be6-808fbbe84772')

resource publishAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: app
  name: guid(app.id, runnerPrincipalId, websiteContributor)
  properties: {
    principalId: runnerPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: websiteContributor
  }
}
