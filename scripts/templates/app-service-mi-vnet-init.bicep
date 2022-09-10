param appServiceName string
param appServicePort string

param location string = resourceGroup().location
param tagsArray object = resourceGroup().tags

module appServiceInit 'app-service-mi-vnet-service.bicep' = {
  name: 'deployment-app-service-mi-vnet-init'
  params: {
    appClientId: ''
    appInsightsConnectionString: ''
    appInsightsInstrumentationKey: ''
    appServiceName: appServiceName
    appServicePort: appServicePort
    springDatasourceUrl: ''
    springDatasourceUserName: ''
    location: location
    springDatasourceShowSql: 'true'
    tagsArray: tagsArray
  }
}
