param logAnalyticsWorkspaceName string
param logAnalyticsWorkspaceRG string
param appInsightsName string
param keyVaultName string
param dbServerName string
param dbName string

@secure()
param dbAdminName string
@secure()
param dbAdminPassword string
@secure()
param dbUserName string
param containerRegistryName string
param containerInstanceName string
param containerInstanceIdentityName string
param containerAppName string
param containerAppPort string
param containerImageName string
param deploymentClientIPAddress string

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
    authConfig: {
      activeDirectoryAuthEnabled: true
      passwordAuthEnabled: true
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

resource containerUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: containerInstanceIdentityName
  location: location
  tags: tagsArray
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

module rbacContainerRegistryACRPull './components/role-assignment-container-registry.bicep' = {
  name: 'deployment-rbac-container-registry-acr-pull'
  params: {
    containerRegistryName: containerRegistryName
    roleDefinitionId: acrPullRole.id
    principalId: containerUserManagedIdentity.properties.principalId
    roleAssignmentNameGuid: guid(resourceGroup().id, containerRegistry.id, acrPullRole.id)
  }
}

//To use system assigned identities, containerInstance needs to exist before this template runs...
resource containerInstance 'Microsoft.ContainerInstance/containerGroups@2021-10-01' existing = {
  name: containerInstanceName
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
    enabledForTemplateDeployment: true
    enabledForDeployment: true
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

resource kvSecretAppClientId 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'SPRING-DATASOURCE-APP-CLIENT-ID'
  properties: {
    value: containerInstance.identity.principalId
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

resource kvDiagnotsicsLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${keyVaultName}-kv-logs'
  scope: keyVault
  dependsOn: [
    containerInstanceConfig
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

@description('This is the built-in AcrPull role. See https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#acrpull')
resource acrPullRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}

@description('This is the built-in Key Vault Secrets User role. See https://docs.microsoft.com/en-gb/azure/role-based-access-control/built-in-roles#key-vault-secrets-user')
resource keyVaultSecretsUser 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: keyVault
  name: '4633458b-17de-408a-b874-0445c86b69e6'
}

module rbacKVSpringDataSourceURL './components/role-assignment-kv-secret.bicep' = {
  name: 'deployment-rbac-kv-secret-app-spring-datasource-url'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: containerInstance.identity.principalId
    roleAssignmentNameGuid: guid(containerInstance.id, kvSecretSpringDataSourceURL.id, keyVaultSecretsUser.id)
    kvName: keyVault.name
    kvSecretName: kvSecretSpringDataSourceURL.name
  }
}

module rbacKVSecretAppClientId './components/role-assignment-kv-secret.bicep' = {
  name: 'deployment-rbac-kv-secret-app-client-id'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: containerInstance.identity.principalId
    roleAssignmentNameGuid: guid(containerInstance.id, kvSecretAppClientId.id, keyVaultSecretsUser.id)
    kvName: keyVault.name
    kvSecretName: kvSecretAppClientId.name
  }
}

module rbacKVSecretDbUserName './components/role-assignment-kv-secret.bicep' = {
  name: 'deployment-rbac-kv-secret-db-user-name'
  params: {
    roleDefinitionId: keyVaultSecretsUser.id
    principalId: containerInstance.identity.principalId
    roleAssignmentNameGuid: guid(containerInstance.id, kvSecretDbUserName.id, keyVaultSecretsUser.id)
    kvName: keyVault.name
    kvSecretName: kvSecretDbUserName.name
  }
}

module containerInstanceConfig 'container-instance-mi-service.bicep' = {
  name: 'deployment-container-instance-core'
  params: {
    containerInstanceName: containerInstanceName
    appClientId: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvSecretAppClientId.name})'
    containerAppName: containerAppName
    containerImage: containerImageName
    containerInstanceIdentityName: containerUserManagedIdentity.name
    appInsightsConnectionString: appInsights.properties.ConnectionString
    appInsightsInstrumentationKey: appInsights.properties.InstrumentationKey
    springDatasourceUrl: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvSecretSpringDataSourceURL.name})'
    springDatasourceUserName: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvSecretDbUserName.name})'
    springDatasourceShowSql: 'true'
    containerAppPort: containerAppPort
    location: location
    tagsArray: tagsArray
  }
}
