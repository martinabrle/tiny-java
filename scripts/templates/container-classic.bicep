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
param containerInstanceIdentityName string = '${containerInstanceName}user-identity'
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

resource postgreSQLServer 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' = {
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
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Enabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }

    administratorLogin: dbAdminName
    administratorLoginPassword: dbAdminPassword
  }
}

resource postgreSQLDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2022-12-01' = {
  parent: postgreSQLServer
  name: dbName
  properties: {
    charset: 'utf8'
    collation: 'en_US.utf8'
  }
}

resource allowClientIPFirewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2022-12-01' = {
  name: 'AllowDeploymentClientIP'
  parent: postgreSQLServer
  properties: {
    endIpAddress: deploymentClientIPAddress
    startIpAddress: deploymentClientIPAddress
  }
}

resource allowAllIPsFirewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2022-12-01' = {
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

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
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

@description('This is the built-in AcrPull role. See https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#acrpull')
resource acrPullRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup()
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
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

// For some weird reason, when I deploy a managed identity before the container instance, deployment fails
// This is why the deployment is split into two separate bicep templates for the same container instance,
// where the params need to be synced manually (between this one and ...instance-service.bicep)
resource containerUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: containerInstanceIdentityName
  // dependsOn: [
  //   containerInstance
  // ]
  location: location
  tags: tagsArray
}

resource containerInstance 'Microsoft.ContainerInstance/containerGroups@2022-10-01-preview' = {
  name: containerInstanceName
  location: location
  tags: tagsArray
  identity: {
    type:'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/${subscription().subscriptionId}/resourcegroups/${resourceGroup().name}/providers/microsoft.managedidentity/userassignedidentities/${containerInstanceIdentityName}': {}
    }
  }
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
      dnsNameLabel: replace(replace(containerInstanceName, '-', ''), '_', '')
    }
    containers: [
      {
        name: containerAppName
        properties: {
          image: containerImageName
          livenessProbe: {
            httpGet: {
              port: 80
              path: contains(containerImageName, 'aci-helloworld') ? '/' : '/actuator/health/liveness' //initial deployment has an aci-helloworld from mcr deployed
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
              path: contains(containerImageName, 'aci-helloworld') ? '/' : '/actuator/health/readiness' //initial deployment has an aci-helloworld from mcr deployed
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
              name: 'SPRING_DATASOURCE_USERNAME'
              value: dbUserName
            }
            {
              name: 'SPRING_DATASOURCE_PASSWORD'
              value: dbUserPassword
            }
            {
              name: 'SPRING_PROFILES_ACTIVE'
              value: 'test'
            }
            {
              name: 'PORT'
              value: string(containerAppPort)
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
