param containerInstanceName string
param containerInstanceIdentityName string
@secure()
param appClientId string
param containerAppName string
param containerImage string
@secure()
param appInsightsConnectionString string
@secure()
param appInsightsInstrumentationKey string
@secure()
param springDatasourceUrl string
@secure()
param springDatasourceUserName string
param springDatasourceShowSql string
param containerAppPort string
param appSpringProfile string

param location string = resourceGroup().location

param tagsArray object = resourceGroup().tags

resource containerInstance 'Microsoft.ContainerInstance/containerGroups@2021-10-01' = {
  name: containerInstanceName
  location: location
  tags: tagsArray
  identity: {
    type: 'SystemAssigned, UserAssigned'
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
      dnsNameLabel: containerInstanceName
    }
    containers: [
      {
        name: containerAppName
        properties: {
          image: containerImage
          environmentVariables: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsightsConnectionString
            }
            {
              name: 'APP_INSIGHTS_INSTRUMENTATION_KEY'
              value: appInsightsInstrumentationKey
            }
            {
              name: 'SPRING_DATASOURCE_URL'
              value: springDatasourceUrl
            }
            {
              name: 'SPRING_DATASOURCE_APP_CLIENT_ID'
              value: appClientId
            }
            {
              name: 'SPRING_DATASOURCE_USERNAME'
              value: springDatasourceUserName
            }
            {
              name: 'SPRING_PROFILES_ACTIVE'
              value: appSpringProfile
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
            {
              name: 'TEST_KEYVAULT_REFERENCE'
              value: '@Microsoft.KeyVault(VaultName=maabrle-tiny-java-app-ci;SecretName=SPRING-DATASOURCE-URL)'
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