# Spring Boot Todo App on App Service

## Deploying Todo App into an App Service with Github actions (CI/CD Pipeline)
* Copy the repo's content into your personal or organizational GitHub Account
* Create a new environment called ```APP-SERVICE``` in *GitHub->Settings->Environments*
* Click on this environment
* Open your repository in the browser and select *Settings->Secrets->Actions*
* Set the following GitHub action variables:
```
AZURE_SUBSCRIPTION_ID
AZURE_CREDENTIALS
AZURE_DBA_GROUP_NAME
AZURE_LOCATION
AZURE_RESOURCE_TAGS

AZURE_LOG_ANALYTICS_WRKSPC_NAME
AZURE_LOG_ANALYTICS_WRKSPC_RESOURCE_GROUP

AZURE_RESOURCE_GROUP

AZURE_APP_INSIGHTS_NAME

AZURE_KEY_VAULT_NAME

AZURE_DB_SERVER_NAME
AZURE_DB_NAME

AZURE_APP_NAME
AZURE_APP_PORT

```
* Create a service principal and assigned roles needed for deploying resources, managing Key Vault secrets and assigning RBACs 
```
az ad sp create-for-rbac --name {YOUR_DEPLOYMENT_PRINCIPAL_NAME} --role "Key Vault Administrator" --scopes /subscriptions/{AZURE_SUBSCRIPTION_ID} --sdk-auth
az ad sp create-for-rbac --name {YOUR_DEPLOYMENT_PRINCIPAL_NAME} --role contributor --scopes /subscriptions/{AZURE_SUBSCRIPTION_ID} --sdk-auth
az ad sp create-for-rbac --name {YOUR_DEPLOYMENT_PRINCIPAL_NAME} --role owner --scopes /subscriptions/{AZURE_SUBSCRIPTION_ID} --sdk-auth
```
* Copy the output JSON into a new variable ```AZURE_CREDENTIALS``` in *Settings->Secrets->Actions* in your GitHub Repo
* Add ```Owner``` and ```Contributor``` roles to the newly created service principal
* Check all three roles (Owner, Contributor and Key Vault Administrator) have been assigned correctly
```
az role assignment list --assignee {SERVICE_PRINCIPAL_FROM_JSON_OUTPUT} -o table
```
* If you are using managed identities, you will need to provide the newly created service principal with a Directory.Read.All AD role for the workflow to work
* This may not be ideal, if you are not using a separated subscription for each workload as a part of your landing zones; the alternative is to modify deployment scripts so that these do not create resource groups and give RBAC contributor, owner and Key Vault administrator roles to the deployment service principal on the reasource group ```{YOUR_RG_NAME_rg}```. However, using a subscription per workload and giving the deployment service principle these roles allows us to have ```{YOUR_RG_NAME_rg}``` only automatically created and deleted. By deleting the resource group, Azure Resource Manager makes sure that resources have been deleted in the right order, otherwise you would have the responsibility  to delete resources in the right order. We should switch here to OICD as described [here](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-azure#use-the-azure-login-action-with-openid-connect) to avoid relying on storing deployment credentials
* Run the infrastructure deployment by running *Actions-cicd-app-service-infra* manually; this action is defined in ```./tiny-java/.github/workflows/cicd-spp-service-infra.yml```
* Run the code deployment by running *Actions->cicd-app-service* manually; this action is defined in ```./tiny-java/.github/workflows/cicd-app-service.yml```
* Open the app's URL (```https://${AZURE_APP_NAME}.azurewebsites.net/```) in the browser and test it by creating and reviewing tasks
* Explore the SCM console on (```https://${AZURE_APP_NAME}.scm.azurewebsites.net/```); check logs and bash
* Delete created resources by running *Actions->Cleanup*
