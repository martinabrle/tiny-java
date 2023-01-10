param logAnalyticsWorkspaceName string
param logAnalyticsWorkspaceRG string
param appInsightsName string

param keyVaultName string
param dbServerName string
param dbName string
param createDB bool = true

@secure()
param dbAdminName string
@secure()
param dbAdminPassword string
@secure()
param dbUserName string
@secure()
param dbUserPassword string
@secure()
param dbStagingUserName string
@secure()
param dbStagingUserPassword string

param appServiceName string
param appServicePort string

param deploymentClientIPAddress string

param healthCheckPath string = '/'

param location string = resourceGroup().location

param tagsArray object = resourceGroup().tags

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
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
    name: 'Standard_B4ms'
    tier: 'Burstable'
    Standard_B4ms
  }
  properties: {
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    createMode: 'Default'
    version: '14'
    storage: {
      storageSizeGB: 5
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
  name: '${dbServerName}-db-logs'
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


resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: '${appServiceName}-plan'
  location: location
  tags: tagsArray
  properties: {
    reserved: true
  }
  sku: {
    name: 'S2'
  }
  kind: 'linux'
}

resource appService 'Microsoft.Web/sites@2021-03-01' = {
  name: appServiceName
  location: location
  tags: tagsArray
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'JAVA|11-java11'
      scmType: 'None'
      healthCheckPath: healthCheckPath
    }
  }
}

resource appServiceStaging 'Microsoft.Web/sites/slots@2021-03-01' = {
  parent: appService
  name: 'staging'
  location: location
  tags: tagsArray
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'JAVA|11-java11'
      scmType: 'None'
    }
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  dependsOn: [
    appInsights
  ]
  location: location
  tags: tagsArray
  properties: {
    createMode: 'default'
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
  }
}

resource kvApplicationInsightsConnectionString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'APPLICATIONINSIGHTS-CONNECTION-STRING'
  properties: {
    value: appInsights.properties.ConnectionString
    contentType: 'string'
  }
}

resource kvSecretAppInsightsInstrumentationKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'APPINSIGHTS-INSTRUMENTATIONKEY'
  properties: {
    value: appInsights.properties.InstrumentationKey
    contentType: 'string'
  }
}

resource kvSecretSpringDataSourceURL 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'SPRING-DATASOURCE-URL'
  properties: {
    value: 'jdbc:postgresql://${dbServerName}.postgres.database.azure.com:5432/${dbName}'
    contentType: 'string'
  }
}

resource kvSecretDbUserName 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: keyVault
  name: 'SPRING-DATASOURCE-USERNAME'
  properties: {
    value: dbUserName
    contentType: 'string'
  }
}

resource kvSecretDbStagingUserName 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'SPRING-DATASOURCE-USERNAME-STAGING'
  properties: {
    value: dbStagingUserName
    contentType: 'string'
  }
}

resource kvSecretDbUserPassword 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'SPRING-DATASOURCE-PASSWORD'
  properties: {
    value: dbUserPassword
    contentType: 'string'
  }
}

resource kvSecretDbStagingUserPassword 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'SPRING-DATASOURCE-PASSWORD-STAGING'
  properties: {
    value: dbStagingUserPassword
    contentType: 'string'
  }
}

resource kvDiagnotsicsLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${keyVaultName}-kv-logs'
  scope: keyVault
  dependsOn: [
    appServicePARMS
  ]
  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
      {
        categoryGroup: 'audit'
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

resource appServiceDiagnotsicsLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${appServiceName}-app-logs'
  scope: appService
  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
      {
        categoryGroup: 'audit'
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

@description('This is the built-in Key Vault Secrets User role. See https://docs.microsoft.com/en-gb/azure/role-based-access-control/built-in-roles#key-vault-secrets-user')
resource keyVaultSecretsUser 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: keyVault
  name: '4633458b-17de-408a-b874-0445c86b69e6'
}

module rbacKVApplicationInsightsConnectionString './components/role-assignment-kv-secret.bicep' = {
  name: 'deployment-rbac-kv-secret-app-insights-con-str'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: appService.identity.principalId
    roleAssignmentNameGuid: guid(appService.id, kvApplicationInsightsConnectionString.id, keyVaultSecretsUser.id)
    kvName: keyVault.name
    kvSecretName: kvApplicationInsightsConnectionString.name
  }
}

module rbacKVApplicationInsightsConnectionString2 './components/role-assignment-kv-secret.bicep' = {
  name: 'deployment-rbac-kv-secret-app-insights-con-str2'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: appServiceStaging.identity.principalId
    roleAssignmentNameGuid: guid(appServiceStaging.id, kvApplicationInsightsConnectionString.id, keyVaultSecretsUser.id)
    kvName: keyVault.name
    kvSecretName: kvApplicationInsightsConnectionString.name
  }
}

module rbacKVAppInsightsInstrKey './components/role-assignment-kv-secret.bicep' = {
  name: 'deployment-rbac-kv-secret-app-insights-instr'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: appService.identity.principalId
    roleAssignmentNameGuid: guid(appService.id, kvSecretAppInsightsInstrumentationKey.id, keyVaultSecretsUser.id)
    kvName: keyVault.name
    kvSecretName: kvSecretAppInsightsInstrumentationKey.name
  }
}

module rbacKVAppInsightsInstrKey2 './components/role-assignment-kv-secret.bicep' = {
  name: 'deployment-rbac-kv-secret-app-insights-instr2'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: appServiceStaging.identity.principalId
    roleAssignmentNameGuid: guid(appServiceStaging.id, kvSecretAppInsightsInstrumentationKey.id, keyVaultSecretsUser.id)
    kvName: keyVault.name
    kvSecretName: kvSecretAppInsightsInstrumentationKey.name
  }
}

module rbacKVSpringDataSourceURL './components/role-assignment-kv-secret.bicep' = {
  name: 'deployment-rbac-kv-secret-app-spring-datasource-url'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: appService.identity.principalId
    roleAssignmentNameGuid: guid(appService.id, kvSecretSpringDataSourceURL.id, keyVaultSecretsUser.id)
    kvName: keyVault.name
    kvSecretName: kvSecretSpringDataSourceURL.name
  }
}

module rbacKVSpringDataSourceURL2 './components/role-assignment-kv-secret.bicep' = {
  name: 'deployment-rbac-kv-secret-app-spring-datasource-url2'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: appServiceStaging.identity.principalId
    roleAssignmentNameGuid: guid(appServiceStaging.id, kvSecretSpringDataSourceURL.id, keyVaultSecretsUser.id)
    kvName: keyVault.name
    kvSecretName: kvSecretSpringDataSourceURL.name
  }
}

module rbacKVSecretDbUserName './components/role-assignment-kv-secret.bicep' = {
  name: 'deployment-rbac-kv-secret-db-user-name'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: appService.identity.principalId
    roleAssignmentNameGuid: guid(appService.id, kvSecretDbUserName.id, keyVaultSecretsUser.id)
    kvName: keyVault.name
    kvSecretName: kvSecretDbUserName.name
  }
}

module rbacKVSecretDbStagingUserName './components/role-assignment-kv-secret.bicep' = {
  name: 'deployment-rbac-kv-secret-db-stage-user-name'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: appServiceStaging.identity.principalId
    roleAssignmentNameGuid: guid(appServiceStaging.id, kvSecretDbStagingUserName.id, keyVaultSecretsUser.id)
    kvName: keyVault.name
    kvSecretName: kvSecretDbStagingUserName.name
  }
}

module rbacKVSecretDbUserPassword './components/role-assignment-kv-secret.bicep' = {
  name: 'deployment-rbac-kv-secret-app-client-id'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: appService.identity.principalId
    roleAssignmentNameGuid: guid(appService.id, kvSecretDbUserPassword.id, keyVaultSecretsUser.id)
    kvName: keyVault.name
    kvSecretName: kvSecretDbUserPassword.name
  }
}

module rbacKVSecretDbStagingUserPassword './components/role-assignment-kv-secret.bicep' = {
  name: 'deployment-rbac-kv-secret-stage-app-client-id'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: appServiceStaging.identity.principalId
    roleAssignmentNameGuid: guid(appServiceStaging.id, kvSecretDbStagingUserPassword.id, keyVaultSecretsUser.id)
    kvName: keyVault.name
    kvSecretName: kvSecretDbStagingUserPassword.name
  }
}

resource appServiceSlotConfigNames 'Microsoft.Web/sites/config@2021-03-01' = {
  name: 'slotConfigNames'
  kind: 'string'
  parent: appService
  dependsOn: [ appServicePARMS ]
  properties: {
    appSettingNames: [
      'SPRING_DATASOURCE_URL', 'SPRING_DATASOURCE_USERNAME', 'SPRING_DATASOURCE_PASSWORD', 'APPLICATIONINSIGHTS_CONNECTION_STRING', 'APPINSIGHTS_INSTRUMENTATIONKEY', 'SPRING_PROFILES_ACTIVE', 'PORT', 'SPRING_DATASOURCE_SHOW_SQL', 'DEBUG_AUTH_TOKEN'
    ]
  }
}

resource appServicePARMS 'Microsoft.Web/sites/config@2021-03-01' = {
  name: 'web'
  parent: appService
  kind: 'string'
  dependsOn: [
    rbacKVAppInsightsInstrKey
    rbacKVApplicationInsightsConnectionString
    rbacKVSecretDbUserName
    rbacKVSecretDbUserPassword
    rbacKVSpringDataSourceURL
  ]
  properties: {
    appSettings: [
      {
        name: 'SPRING_DATASOURCE_URL'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvSecretSpringDataSourceURL.name})'
      }
      {
        name: 'SPRING_DATASOURCE_USERNAME'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvSecretDbUserName.name})'
      }
      {
        name: 'SPRING_DATASOURCE_PASSWORD'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvSecretDbUserPassword.name})'
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvApplicationInsightsConnectionString.name})'
      }
      {
        name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvSecretAppInsightsInstrumentationKey.name})'
      }
      {
        name: 'SPRING_PROFILES_ACTIVE'
        value: 'test'
      }
      {
        name: 'PORT'
        value: appServicePort
      }
      {
        name: 'SPRING_DATASOURCE_SHOW_SQL'
        value: 'true'
      }
    ]
  }
}

resource appServiceStagingPARMS 'Microsoft.Web/sites/slots/config@2021-03-01' = {
  name: 'web'
  parent: appServiceStaging
  dependsOn: [
    appServiceSlotConfigNames
    rbacKVAppInsightsInstrKey2
    rbacKVApplicationInsightsConnectionString2
    rbacKVSecretDbStagingUserName
    rbacKVSecretDbStagingUserPassword
    rbacKVSpringDataSourceURL2
  ]
  kind: 'string'
  properties: {
    appSettings: [
      {
        name: 'SPRING_DATASOURCE_URL'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvSecretSpringDataSourceURL.name})'
      }
      {
        name: 'SPRING_DATASOURCE_USERNAME'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvSecretDbStagingUserName.name})'
      }
      {
        name: 'SPRING_DATASOURCE_PASSWORD'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvSecretDbStagingUserPassword.name})'
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvApplicationInsightsConnectionString.name})'
      }
      {
        name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvSecretAppInsightsInstrumentationKey.name})'
      }
      {
        name: 'SPRING_PROFILES_ACTIVE'
        value: 'test'
      }
      {
        name: 'PORT'
        value: appServicePort
      }
      {
        name: 'SPRING_DATASOURCE_SHOW_SQL'
        value: 'true'
      }
    ]
  }
}
