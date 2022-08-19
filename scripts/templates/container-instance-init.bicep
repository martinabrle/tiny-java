param containerInstanceName string
param containerInstanceIdentityName string = '${containerInstanceName}-identity'
param containerAppName string
param containerAppPort string

param location string = resourceGroup().location

param tagsArray object = resourceGroup().tags

resource containerUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: containerInstanceIdentityName
  location: location
  tags: tagsArray
}

module containerInstanceConfig 'container-instance-service.bicep' = {
  name: 'deployment-container-instance-core'
  params: {
      containerInstanceName: containerInstanceName
      containerInstanceIdentityName: containerUserManagedIdentity.name
      appClientId : ''
      containerAppName: containerAppName 
      containerImage : 'mcr.microsoft.com/azuredocs/aci-helloworld:latest'
      appInsightsConnectionString: ''
      appInsightsInstrumentationKey: '' 
      springDatasourceUrl: '' 
      springDatasourceUserName: '' 
      springDatasourceShowSql: ''
      containerAppPort: containerAppPort
      appSpringProfile: ''
      location: location
      tagsArray: tagsArray
  }
}
