param logAnalyticsWorkspaceName string
param logAnalyticsWorkspaceRG string
param appInsightsName string

param keyVaultName string
param dbServerName string
param dbName string
param runnerAdminSshPublicKey string

@secure()
param dbAdminName string
@description('Object ID of the Microsoft Entra group that administers PostgreSQL.')
param dbAdminObjectId string
@secure()
param dbUserName string
param appServiceName string
param appServicePort string

param healthCheckPath string = '/'

param location string = resourceGroup().location

param tagsArray object = resourceGroup().tags

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(logAnalyticsWorkspaceRG)
}

var vnetAddressPrefix = '10.0.0.0/16'

var appSubnetAddressPrefix = '10.0.0.0/24'

var bastionSubnetAddressPrefix = '10.0.1.0/24'
var mgmtSubnetAddressPrefix = '10.0.2.0/24'
var integrationSubnetAddressPrefix = '10.0.3.0/24'
var dbSubnetAddressPrefix = '10.0.4.0/24'
var runnerName = 'tinyjava-${uniqueString(resourceGroup().id, appServiceName)}'

output githubRunnerName string = runnerName

resource runnerEgressIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: '${runnerName}-egress'
  location: location
  tags: tagsArray
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource runnerNat 'Microsoft.Network/natGateways@2024-05-01' = {
  name: '${runnerName}-nat'
  location: location
  tags: tagsArray
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIpAddresses: [
      {
        id: runnerEgressIp.id
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: '${appServiceName}-vnet'
  location: location
  tags: tagsArray
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'web'
        properties: {
          addressPrefix: appSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'mgmt'
        properties: {
          addressPrefix: mgmtSubnetAddressPrefix
          defaultOutboundAccess: false
          natGateway: {
            id: runnerNat.id
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubnetAddressPrefix
        }
      }
      {
        name: 'integration'
        properties: {
          addressPrefix: integrationSubnetAddressPrefix
          delegations: [
            {
              name: 'appService'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: 'db'
        properties: {
          addressPrefix: dbSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

resource dbSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  parent: vnet
  name: 'db'
}

resource webSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  parent: vnet
  name: 'web'
}

resource integrationSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  parent: vnet
  name: 'integration'
}

resource mgmtSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: 'mgmt'
}

module runner './components/vnet-github-runner.bicep' = {
  name: '${runnerName}-vm'
  params: {
    name: runnerName
    subnetId: mgmtSubnet.id
    sshPublicKey: runnerAdminSshPublicKey
    location: location
    tags: tagsArray
  }
}

module runnerAccess './components/vnet-github-runner-access.bicep' = {
  name: '${runnerName}-access'
  params: {
    runnerName: runnerName
    runnerPrincipalId: runner.outputs.principalId
    dbServerName: postgreSQLServer.name
    appServiceName: appService.name
  }
  dependsOn: [
    postgreSQLAdmin
    appService
  ]
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

resource postgreSQLServer 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: dbServerName
  location: location
  tags: tagsArray
  sku: {
    name: 'Standard_D2s_v3'
    tier: 'GeneralPurpose'
  }
  properties: {
    createMode: 'Default'
    version: '16'
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    network: {
      publicNetworkAccess: 'Disabled'
    }
    authConfig: {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Disabled'
      tenantId: subscription().tenantId
    }
  }
}

resource postgreSQLAdmin 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2024-08-01' = {
  parent: postgreSQLServer
  name: dbAdminObjectId
  properties: {
    principalName: dbAdminName
    principalType: 'Group'
    tenantId: subscription().tenantId
  }
}

resource privateEndpointPostgresqlServer 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  location: location
  name: '${dbServerName}-private-endpoint'
  tags: tagsArray
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
  parent: privateEndpointPostgresqlServer
  name: 'default'
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
}

resource pvtEndpointDnsGroupAppService 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  parent: privateEndpointAppService
  name: 'default'
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


resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
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

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: appServiceName
  location: location
  tags: union(tagsArray, { tinyJavaVnetRunner: runnerName })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    virtualNetworkSubnetId: integrationSubnet.id
    publicNetworkAccess: 'Disabled'
    httpsOnly: true

    siteConfig: {
      linuxFxVersion: 'JAVA|11-java11'
      scmType: 'None'
      healthCheckPath: healthCheckPath
      vnetRouteAllEnabled: true
      http20Enabled: true
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
    value: 'jdbc:postgresql://${postgreSQLServer.properties.fullyQualifiedDomainName}:5432/${dbName}'
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

resource appServiceSlotConfigNames 'Microsoft.Web/sites/config@2021-03-01' = {
  name: 'slotConfigNames'
  kind: 'string'
  parent: appService
  dependsOn: [appServicePARMS]
  properties: {
    appSettingNames: [
      'SPRING_DATASOURCE_URL', 'SPRING_DATASOURCE_USERNAME', 'SPRING_DATASOURCE_APP_CLIENT_ID', 'APPLICATIONINSIGHTS_CONNECTION_STRING', 'APPINSIGHTS_INSTRUMENTATIONKEY', 'SPRING_PROFILES_ACTIVE', 'PORT', 'SPRING_DATASOURCE_SHOW_SQL', 'DEBUG_AUTH_TOKEN'
    ]
  }
}

resource appServicePARMS 'Microsoft.Web/sites/config@2021-03-01' = {
  name: 'web'
  parent: appService
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
        value: ''
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
        value: 'prod-mi'
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
    rbacKVAppInsightsInstrKey
    rbacKVApplicationInsightsConnectionString
    rbacKVSecretDbUserName
    rbacKVSpringDataSourceURL
    rbacKVAppInsightsInstrKey2
    rbacKVApplicationInsightsConnectionString2
  ]
  kind: 'string'
  properties: {
    appSettings: [
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
        value: 'local' // Keep hosted-runner smoke tests independent of the private database.
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
