# Spring Boot Todo App on App Service

## Deploying Todo App into an App Service with Github actions (CI/CD Pipeline)
* Copy the repo's content into your personal or organizational GitHub Account
* Create a new environment called ```APP-SERVICE``` in *GitHub->Settings->Environments*
* Add the following GitHub Actions secrets to the `APP-SERVICE` environment (`AZURE_DBA_GROUP_NAME` is required for `MANAGED_IDENTITIES` and `VNET`):
```
AZURE_SUBSCRIPTION_ID
AZURE_CREDENTIALS
AZURE_DB_ADMIN_PASSWORD
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
* `AZURE_DB_ADMIN_PASSWORD` is required for `CLASSIC` and `MANAGED_IDENTITIES` only. Use the existing administrator password for a deployed server, or a new strong password for an isolated new server. The infrastructure and code workflows must use the same value.
* `VNET` also requires a private deployment repository. Add `GH_RUNNER_ADMIN_TOKEN` as a secret scoped to that repository (fine-grained token with repository Administration: read/write) and `AZURE_RUNNER_SSH_PUBLIC_KEY` as an environment variable. Specify only a public SSH key.
* Create a service principal and assigned roles needed for deploying resources, managing Key Vault secrets and assigning RBACs 
```
az ad sp create-for-rbac --name {YOUR_DEPLOYMENT_PRINCIPAL_NAME} --role "Key Vault Administrator" --scopes /subscriptions/{AZURE_SUBSCRIPTION_ID} --sdk-auth
az ad sp create-for-rbac --name {YOUR_DEPLOYMENT_PRINCIPAL_NAME} --role contributor --scopes /subscriptions/{AZURE_SUBSCRIPTION_ID} --sdk-auth
az ad sp create-for-rbac --name {YOUR_DEPLOYMENT_PRINCIPAL_NAME} --role owner --scopes /subscriptions/{AZURE_SUBSCRIPTION_ID} --sdk-auth
```
* Store the service principal JSON in the `AZURE_CREDENTIALS` environment secret. If Azure login reports `AADSTS5000224`, the configured Entra tenant is unavailable. Use credentials for an active tenant with a matching `AZURE_SUBSCRIPTION_ID`, or have the tenant administrator restore access before retrying.
* Add ```Owner``` and ```Contributor``` roles to the newly created service principal
* Check all three roles (Owner, Contributor and Key Vault Administrator) have been assigned correctly
```
az role assignment list --assignee {SERVICE_PRINCIPAL_FROM_JSON_OUTPUT} -o table
```
* If you are using managed identities, you will need to provide the newly created service principal with a Directory.Read.All AD role for the workflow to work
* This may not be ideal, if you are not using a separated subscription for each workload as a part of your landing zones; the alternative is to modify deployment scripts so that these do not create resource groups and give RBAC contributor, owner and Key Vault administrator roles to the deployment service principal on the reasource group ```{YOUR_RG_NAME_rg}```. However, using a subscription per workload and giving the deployment service principle these roles allows us to have ```{YOUR_RG_NAME_rg}``` only automatically created and deleted. By deleting the resource group, Azure Resource Manager makes sure that resources have been deleted in the right order, otherwise you would have the responsibility  to delete resources in the right order. We should switch here to OICD as described [here](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-azure#use-the-azure-login-action-with-openid-connect) to avoid relying on storing deployment credentials
* The [App Service infrastructure workflow](../../.github/workflows/cicd-app-service-infra.yml) compiles its Bicep templates on relevant pushes and on manual runs with **deploy** unchecked. To diagnose the existing Azure sign-in without provisioning, manually enable **check_credentials** and leave **deploy** unchecked.
* To provision infrastructure, run *Actions -> cicd-app-service-infra* manually, check **deploy**, and select `CLASSIC`, `MANAGED_IDENTITIES`, or `VNET`. Leave **run_cleanup** unchecked unless you intend to delete the existing app resource group and purge its Key Vault.
* The [code workflow](../../.github/workflows/cicd-app-service.yml) tests and packages the app on relevant pushes. For a release, run *Actions → cicd-app-service* manually with **deploy** enabled. Before publishing, it creates the database if absent, checks the schema, and ensures the application roles have the required access. Existing data is not reset.
* `CLASSIC` and `MANAGED_IDENTITIES` release from a hosted runner with a temporary PostgreSQL firewall rule. `VNET` uses the [private runner provisioned by the infrastructure workflow](app-service-mi-vnet.md) for both database setup and publishing. No public PostgreSQL firewall rule is used for `VNET`.
* Open the app's URL (```https://${AZURE_APP_NAME}.azurewebsites.net/```) in the browser and test it by creating and reviewing tasks
* Explore the SCM console on (```https://${AZURE_APP_NAME}.scm.azurewebsites.net/```); check logs and bash
* Delete created resources by running *Actions->Cleanup*
