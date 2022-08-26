param springAppsServiceName string
param appName string
param appPort string
param location string = resourceGroup().location
param tagsArray object = resourceGroup().tags

module springAppsInit 'spring-apps-mi-service.bicep' = {
  name: 'deployment-spring-apps-mi-init'
  params: {
    appClientId: ''
    appInsightsConnectionString: ''
    appInsightsInstrumentationKey: ''
    appName: appName
    appPort: appPort
    appSpringProfile: 'test-mi'
    springAppsServiceName: springAppsServiceName
    springDatasourceShowSql: 'true'
    springDatasourceUrl: ''
    springDatasourceUserName: ''
    location: location
    tagsArray: tagsArray
  }
}
