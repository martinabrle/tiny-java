param appName string
param appPort string

param location string = resourceGroup().location
param tagsArray object = resourceGroup().tags

module appServiceInit 'spring-apps-mi-service.bicep' = {
  name: 'deployment-app-service-mi-init'
  params: {
    appClientId: ''
    appInsightsConnectionString: ''
    appInsightsInstrumentationKey: ''
    appName: appName
    appPort: appPort
    appSpringProfile: 'test-mi'
    springAppsServiceName: ''
    springDatasourceUrl: ''
    springDatasourceUserName: ''
    location: location
    springDatasourceShowSql: 'true'
    tagsArray: tagsArray
  }
}
