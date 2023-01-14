param logAnalyticsWorkspaceName string
param logAnalyticsWorkspaceRG string
param appInsightsName string
param dbServerName string
param dbName string

@secure()
param dbAdminName string
@secure()
param dbAdminPassword string
@secure()
param dbUserName string
@secure()
param dbUserPassword string
param containerRegistryName string
param containerInstanceName string
param containerAppName string
param containerAppPort string
param containerImageName string
param deploymentClientIPAddress string
param location string = resourceGroup().location
param tagsArray object = resourceGroup().tags

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(logAnalyticsWorkspaceRG)
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  dependsOn: [
    logAnalyticsWorkspace
  ]
  location: location
  kind: 'java'
  tags: tagsArray
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource postgreSQLServer 'Microsoft.DBforPostgreSQL/flexibleServers@2022-03-08-preview' = {
  name: dbServerName
  location: location
  tags: tagsArray
  sku: {
    name: 'Standard_B2s'
    tier: 'Burstable'
  }
  properties: {
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    createMode: 'Default'
    version: '14'
    storage: {
      storageSizeGB: 32
    }
    highAvailability: {
      mode: 'Disabled'
    }
    administratorLogin: dbAdminName
    administratorLoginPassword: dbAdminPassword
  }
}

resource postgreSQLDatabase 'Microsoft.DBForPostgreSql/flexibleServers/databases@2020-11-05-preview' = {
  parent: postgreSQLServer
  name: dbName
  properties: {
    charset: 'utf8'
    collation: 'en_US.utf8'
  }
}

resource allowClientIPFirewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2022-03-08-preview' = {
  name: 'AllowDeploymentClientIP'
  parent: postgreSQLServer
  properties: {
    endIpAddress: deploymentClientIPAddress
    startIpAddress: deploymentClientIPAddress
  }
}

resource allowAllIPsFirewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2022-03-08-preview' = {
  name: 'AllowAllWindowsAzureIps'
  parent: postgreSQLServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource postgreSQLServerDiagnotsicsLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${dbServerName}-logs'
  scope: postgreSQLServer
  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspace.id
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: containerRegistryName
  location: location
  tags: tagsArray
  sku: {
    name: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    anonymousPullEnabled: true
  }
}

module containerInstance 'container-instance-classic-service.bicep' = {
  name: 'deployment-container-instance-core'
  params: {
    containerInstanceName: containerInstanceName
    containerAppName: containerAppName
    containerImage: containerImageName
    appInsightsConnectionString: appInsights.properties.ConnectionString
    appInsightsInstrumentationKey: appInsights.properties.InstrumentationKey
    springDatasourceUrl: 'jdbc:postgresql://${dbServerName}.postgres.database.azure.com:5432/${dbName}'
    springDatasourceUserName: dbUserName
    springDatasourcePassword: dbUserPassword
    springDatasourceShowSql: 'true'
    containerAppPort: containerAppPort
    location: location
    tagsArray: tagsArray
  }
}
