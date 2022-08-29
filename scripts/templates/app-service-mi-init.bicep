param appServiceName string
param appServicePort string

param location string = resourceGroup().location
param tagsArray object = resourceGroup().tags

module appServiceInit 'spring-apps-mi-service.bicep' = {
  name: 'deployment-app-service-mi-init'
  params: {
    appClientId: ''
    appInsightsConnectionString: ''
    appInsightsInstrumentationKey: ''
    appName: appServiceName
    appPort: appServicePort
    springAppsServiceName: ''
    springDatasourceUrl: ''
    springDatasourceUserName: ''
    location: location
    springDatasourceShowSql: 'true'
    tagsArray: tagsArray
  }
}
