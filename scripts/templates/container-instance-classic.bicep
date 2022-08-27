param logAnalyticsWorkspaceName string
param logAnalyticsWorkspaceRG string
param appInsightsName string
param dbServerName string
param dbName string
param createDB bool
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
param springDatasourceShowSql string = 'true'
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

// module containerInstanceConfig 'container-instance-mi-service.bicep' = {
//   name: 'deployment-container-instance-core'
//   params: {
//     containerInstanceName: containerInstanceName
//     appClientId: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvSecretAppClientId.name})'
//     containerAppName: containerAppName
//     containerImage: containerImageName
//     containerInstanceIdentityName: containerUserManagedIdentity.name
//     appInsightsConnectionString: appInsights.properties.ConnectionString
//     appInsightsInstrumentationKey: appInsights.properties.InstrumentationKey
//     springDatasourceUrl: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvSecretSpringDataSourceURL.name})'
//     springDatasourceUserName: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${kvSecretDbUserName.name})'
//     springDatasourceShowSql: 'true'
//     containerAppPort: containerAppPort
//     location: location
//     tagsArray: tagsArray
//   }
// }
resource containerInstance 'Microsoft.ContainerInstance/containerGroups@2021-10-01' = {
  name: containerInstanceName
  location: location
  tags: tagsArray
  properties: {
    osType: 'Linux'
    restartPolicy: 'OnFailure'
    sku: 'Standard'
    ipAddress: {
      type: 'Public'
      ports: [
        {
          port: int(containerAppPort)
        }
      ]
      dnsNameLabel: replace(replace(containerInstanceName,'-',''),'_','')
    }
    containers: [
      {
        name: containerAppName
        properties: {
          image: containerImageName
          livenessProbe: {
            httpGet: {
              port: 80
              path: contains(containerImageName, 'aci-helloworld') ? '/' : '/health' //initial deployment has an aci-helloworld from mcr deployed
            }
            initialDelaySeconds: 50
            periodSeconds: 3
            failureThreshold: 3
            successThreshold: 2
            timeoutSeconds: 3
          }
          readinessProbe: {
            httpGet: {
              port: 80
              path: contains(containerImageName, 'aci-helloworld') ? '/' : '/health/warmup' //initial deployment has an aci-helloworld from mcr deployed
            }
            initialDelaySeconds: 50
            periodSeconds: 3
            failureThreshold: 3
            successThreshold: 2
            timeoutSeconds: 3
          }
          environmentVariables: [
            {
              name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
              value: appInsights.properties.InstrumentationKey
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsights.properties.ConnectionString
            }
            {
              name: 'SPRING_DATASOURCE_URL'
              value: 'jdbc:postgresql://${dbServerName}.postgres.database.azure.com:5432/${dbName}'
            }
            {
              name: 'SPRING_DATASOURCE_PASSWORD'
              value: dbUserName
            }
            {
              name: 'SPRING_DATASOURCE_USERNAME'
              value: dbUserPassword
            }
            {
              name: 'SPRING_PROFILES_ACTIVE'
              value: 'test-mi'
            }
            {
              name: 'PORT'
              value: string(containerAppPort)
            }
            {
              name: 'SPRING_DATASOURCE_SHOW_SQL'
              value: springDatasourceShowSql
            }
            {
              name: 'DEBUG_AUTH_TOKEN'
              value: 'true'
            }
          ]
          ports: [
            {
              port: int(containerAppPort)
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 1
            }
          }
        }
      }
    ]
  }
}
