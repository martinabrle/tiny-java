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
param dbStagingUserName string
param appClientId string = ''
param stagingAppClientId string = ''
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

resource postgreSQLServer 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: dbServerName
  location: location
  tags: tagsArray
  sku: {
    name: 'B_Gen5_1'
    tier: 'Basic'
    family: 'Gen5'
    capacity: 1
  }
  properties: {
    storageProfile: {
      storageMB: 5120
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
      storageAutogrow: 'Disabled'
    }
    createMode: 'Default'
    version: '11'
    sslEnforcement: 'Enabled'
    minimalTlsVersion: 'TLSEnforcementDisabled'
    infrastructureEncryption: 'Disabled'
    publicNetworkAccess: 'Enabled'
    administratorLogin: dbAdminName
    administratorLoginPassword: dbAdminPassword
  }
}

resource postgreSQLDatabase 'Microsoft.DBforPostgreSQL/servers/databases@2017-12-01' = if (createDB) {
  parent: postgreSQLServer
  name: dbName
  properties: {
    charset: 'utf8'
    collation: 'en_US.utf8'
  }
}

resource allowClientIPFirewallRule 'Microsoft.DBforPostgreSQL/servers/firewallRules@2017-12-01' = {
  name: 'AllowDeploymentClientIP'
  parent: postgreSQLServer
  properties: {
    endIpAddress: deploymentClientIPAddress
    startIpAddress: deploymentClientIPAddress
  }
}

resource allowAllIPsFirewallRule 'Microsoft.DBforPostgreSQL/servers/firewallRules@2017-12-01' = {
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

// resource authSettings 'Microsoft.Web/sites/config@2022-03-01' existing = {
//   name: 'authsettingsV2'
//   parent: appService
// }

// resource authSettings 'Microsoft.Web/sites/config@2020-12-01' existing = {
//   name: '${appService.name}/authsettingsV2'
// }

// resource authsettings 'Microsoft.Web/sites/config@2021-03-01' = {
//   name: 'authsettingsV2'
//   parent: appService
//   properties: {
//     identityProviders: {
//       azureActiveDirectory: {
//         enabled: true
//         isAutoProvisioned: true
//       }
//     }
//   }
// }

// var appClientId = authsettings.properties.identityProviders.azureActiveDirectory.registration.clientId
// var appClientId = authsettings.properties.identityProviders.azureActiveDirectory.registration.clientId

resource kvSecretAppClientId 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'SPRING-DATASOURCE-APP-CLIENT-ID'
  properties: {
    value: appClientId
    contentType: 'string'
  }
}

resource kvSecretAppClientIdStaging 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'SPRING-DATASOURCE-APP-CLIENT-ID-STAGING'
  properties: {
    value: stagingAppClientId
    contentType: 'string'
  }
}

resource kvSecretDbUserName 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
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

resource kvDiagnotsicsLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${keyVaultName}-kv-logs'
  scope: keyVault
  dependsOn: [
    appService
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

module rbacKVSecretAppClientId './components/role-assignment-kv-secret.bicep' = {
  name: 'deployment-rbac-kv-secret-app-client-id'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: appService.identity.principalId
    roleAssignmentNameGuid: guid(appService.id, kvSecretAppClientId.id, keyVaultSecretsUser.id)
    kvName: keyVault.name
    kvSecretName: kvSecretAppClientId.name
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
  name: 'deployment-rbac-kv-secret-db-user-name-staging'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: appServiceStaging.identity.principalId
    roleAssignmentNameGuid: guid(appServiceStaging.id, kvSecretDbStagingUserName.id, keyVaultSecretsUser.id)
    kvName: keyVault.name
    kvSecretName: kvSecretDbStagingUserName.name
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

module rbacKVSecretAppClientIdStaging './components/role-assignment-kv-secret.bicep' = {
  name: 'deployment-rbac-kv-secret-app-client-id-staging'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: appServiceStaging.identity.principalId
    roleAssignmentNameGuid: guid(appServiceStaging.id, kvSecretAppClientIdStaging.id, keyVaultSecretsUser.id)
    kvName: keyVault.name
    kvSecretName: kvSecretAppClientIdStaging.name
  }
}

resource appServiceDefaultSlot 'Microsoft.Web/sites/slots@2021-03-01' existing = {
  name: appService.name
}

resource appServicePARMS 'Microsoft.Web/sites/slots/config@2021-03-01' = {
  name: 'web'
  parent: appServiceDefaultSlot
  dependsOn: [
    rbacKVAppInsightsInstrKey
    rbacKVApplicationInsightsConnectionString
    rbacKVSecretAppClientId
    rbacKVSecretDbUserName
    rbacKVSpringDataSourceURL
    rbacKVAppInsightsInstrKey2
    rbacKVApplicationInsightsConnectionString2
    rbacKVSecretAppClientIdStaging
    rbacKVSecretDbStagingUserName
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
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvSecretDbUserName.name})'
      }
      {
        name: 'SPRING_DATASOURCE_APP_CLIENT_ID'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvSecretAppClientId.name})'
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
        value: 'test-mi'
      }
      {
        name: 'PORT'
        value: appServicePort
      }
      {
        name: 'SPRING_DATASOURCE_SHOW_SQL'
        value: 'true'
      }
      {
        name: 'DEBUG_AUTH_TOKEN'
        value: 'true'
      }
    ]
  }
}

resource appServiceStagingPARMS 'Microsoft.Web/sites/slots/config@2021-03-01' = {
  name: 'web'
  parent: appServiceStaging
  dependsOn: [
    rbacKVAppInsightsInstrKey
    rbacKVApplicationInsightsConnectionString
    rbacKVSecretAppClientId
    rbacKVSecretDbUserName
    rbacKVSpringDataSourceURL
    rbacKVAppInsightsInstrKey2
    rbacKVApplicationInsightsConnectionString2
    rbacKVSecretAppClientIdStaging
    rbacKVSecretDbStagingUserName
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
        name: 'SPRING_DATASOURCE_APP_CLIENT_ID'
        value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvSecretAppClientIdStaging.name})'
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
        value: 'test-mi'
      }
      {
        name: 'PORT'
        value: appServicePort
      }
      {
        name: 'SPRING_DATASOURCE_SHOW_SQL'
        value: 'true'
      }
      {
        name: 'DEBUG_AUTH_TOKEN'
        value: 'true'
      }
    ]
  }
}
