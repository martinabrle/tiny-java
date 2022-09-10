param appClientId string
param appInsightsConnectionString string
param appInsightsInstrumentationKey string
param springDatasourceUrl string
param springDatasourceUserName string
param springDatasourceShowSql string = 'true'
param appServiceName string
param appServicePort string

param location string = resourceGroup().location
param tagsArray object = resourceGroup().tags

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${appServiceName}-plan'
  location: location
  tags: tagsArray
  properties: {
    reserved: true
  }
  sku: {
    name: 'S1'
  }
  kind: 'linux'
}

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: appServiceName
  location: location
  tags: tagsArray
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    virtualNetworkSubnetId: vnet.properties.subnets[0].id
    httpsOnly: true

    siteConfig: {
      linuxFxVersion: 'JAVA|11-java11'
      scmType: 'None'
      healthCheckPath: '/health'
      vnetRouteAllEnabled: true
      http20Enabled: true
    }
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
        value: springDatasourceUrl
      }
      {
        name: 'SPRING_DATASOURCE_USERNAME'
        value: springDatasourceUserName
      }
      {
        name: 'SPRING_DATASOURCE_APP_CLIENT_ID'
        value: appClientId
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: appInsightsConnectionString
      }
      {
        name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
        value: appInsightsInstrumentationKey
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
        value: springDatasourceShowSql
      }
    ]
  }
}

var vnetAddressPrefix = '10.0.0.0/16'

var appSubnetAddressPrefix = '10.0.0.0/24'

var mgmtSubnetAddressPrefix = '10.0.1.0/24'

var dbSubnetAddressPrefix = '10.0.4.0/24'

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
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
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: 'mgmt'
        properties: {
          addressPrefix: mgmtSubnetAddressPrefix
        }
      }
      {
        name: 'db'
        properties: {
          addressPrefix: dbSubnetAddressPrefix
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/singleServers'
              }
            }
          ]
        }
      }
    ]
  }
}
