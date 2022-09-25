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

param appServiceName string
param appServicePort string

param deploymentClientIPAddress string

param location string = resourceGroup().location

param tagsArray object = resourceGroup().tags

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(logAnalyticsWorkspaceRG)
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: '${appServiceName}-vnet'
}

resource dbSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  parent: vnet
  name: 'db'
}

resource webSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  parent: vnet
  name: 'web'
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
    name: 'GP_Gen5_2' //Basic tier does not support private endpoints
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 2
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

// resource dbPrivateEndpoint 'Microsoft.DBforPostgreSQL/servers/privateEndpointConnections@2018-06-01' = {
//   name: 'PrivateEndpointConnection'
//   parent: postgreSQLServer
//   properties: {
//     privateEndpoint: dbSubnet
//   }
// }

// We deploy VNET with subnets
// Subnet "web"
// Subnet "db"
//  Private endpoint '${dbServerName}-private-endpoint' connected to DB via a private link connection
//  Private DNS Zone 'privatelink.postgres.database.azure.com', connected to the VNET / Subnet
//    Private DNS Zone Group  '${privateEndpointPostgresqlServer.name}/default', connecting pgsql.id to that dns zone


resource privateEndpointPostgresqlServer 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  location: location
  name: '${dbServerName}-private-endpoint'
  tags: tagsArray
  dependsOn: [
    vnet
  ]
  properties: {
    subnet: {
      id: dbSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: '${dbServerName}-private-endpoint'
        properties: {
          privateLinkServiceId: postgreSQLServer.id
          groupIds: [ 'postgresqlServer' ]
        }
      }
    ]
    customNetworkInterfaceName: '${dbServerName}-private-endpoint-nic'
  }
}

resource privateEndpointAppService 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  location: location
  name: '${appServiceName}-private-endpoint'
  tags: tagsArray
  dependsOn: [
    vnet
  ]
  properties: {
    subnet: {
      id: webSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: '${appServiceName}-private-endpoint'
        properties: {
          privateLinkServiceId: appService.id
          groupIds: [ 'sites' ]
        }
      }
    ]
    customNetworkInterfaceName: '${appServiceName}-private-endpoint-nic'
  }
}

resource privateDNSZonePostgresqlServer 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: 'privatelink.postgres.database.azure.com'
  location: 'global'
  tags: tagsArray
}

resource privateDNSZoneAppService 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: 'privatelink.azurewebsites.net'
  location: 'global'
  tags: tagsArray
}

resource privateLinkDNSZonePostgresqlServer 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDNSZonePostgresqlServer
  name: 'link'
  location: 'global'
  tags: tagsArray
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}

resource privateLinkDNSZoneAppService 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDNSZoneAppService
  name: 'link'
  location: 'global'
  tags: tagsArray
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}

resource pvtEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: '${privateEndpointPostgresqlServer.name}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-postgres-database-azure-com'
        properties: {
          privateDnsZoneId: privateDNSZonePostgresqlServer.id
        }
      }
    ]
  }
  dependsOn: [
    privateEndpointPostgresqlServer
  ]
}

resource pvtEndpointDnsGroupAppService 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: '${privateEndpointAppService.name}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azurewebsites-net'
        properties: {
          privateDnsZoneId: privateDNSZoneAppService.id
        }
      }
    ]
  }
  dependsOn: [
    privateEndpointAppService
  ]
}

// https://docs.microsoft.com/en-us/azure/private-link/create-private-endpoint-bicep?tabs=CLI

// resource privateEndpointName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
//   name: '${privateEndpoint.name}/default'
//   properties: {
//     privateDnsZoneConfigs: [
//       {
//         name: 'privatelink-postgres-database-azure-com'
//         properties: {
//           privateDnsZoneId: privateLinkDNSZonePostgresqlServer.id
//         }
//       }
//     ]
//   }
// }

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

resource appService 'Microsoft.Web/sites@2021-03-01' existing = {
  name: appServiceName
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
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

resource kvApplicationInsightsConnectionString 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: keyVault
  name: 'APPLICATIONINSIGHTS-CONNECTION-STRING'
  properties: {
    value: appInsights.properties.ConnectionString
    contentType: 'string'
  }
}

resource kvSecretAppInsightsInstrumentationKey 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: keyVault
  name: 'APPINSIGHTS-INSTRUMENTATIONKEY'
  properties: {
    value: appInsights.properties.InstrumentationKey
    contentType: 'string'
  }
}

resource kvSecretSpringDataSourceURL 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: keyVault
  name: 'SPRING-DATASOURCE-URL'
  properties: {
    value: 'jdbc:postgresql://${dbServerName}.postgres.database.azure.com:5432/${dbName}'
    contentType: 'string'
  }
}

resource kvSecretAppClientId 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: keyVault
  name: 'SPRING-DATASOURCE-APP-CLIENT-ID'
  properties: {
    value: appService.identity.principalId
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

resource kvDiagnotsicsLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${keyVaultName}-kv-logs'
  scope: keyVault
  dependsOn: [
    appServiceConfig
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
resource keyVaultSecretsUser 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
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

module appServiceConfig 'app-service-mi-service.bicep' = {
  name: 'deployment-app-service-mi-service'
  dependsOn: [
    rbacKVAppInsightsInstrKey
    rbacKVApplicationInsightsConnectionString
    rbacKVSecretAppClientId
    rbacKVSecretDbUserName
    rbacKVSpringDataSourceURL
  ]
  params: {
    appClientId: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvSecretAppClientId.name})'
    appInsightsConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvApplicationInsightsConnectionString.name})'
    appInsightsInstrumentationKey: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvSecretAppInsightsInstrumentationKey.name})'
    appServiceName: appServiceName
    appServicePort: appServicePort
    springDatasourceUrl: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvSecretSpringDataSourceURL.name})'
    springDatasourceUserName: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvSecretDbUserName.name})'
    location: location
    springDatasourceShowSql: 'true'
    tagsArray: tagsArray
  }
}
