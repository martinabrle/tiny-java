# Spring Boot Todo App on App Service

## Deploying Todo App into an App Service with Github actions (CI/CD Pipeline)
* Copy the repo's content into your personal or organizational GitHub Account
* Create a new environment called ```APP-SERVICE``` in *GitHub->Settings->Environments*
* Add the following GitHub Actions secrets to the `APP-SERVICE` environment (`AZURE_DBA_GROUP_NAME` is required for `MANAGED_IDENTITIES` and `VNET`):
```
AZURE_SUBSCRIPTION_ID
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
* `VNET` requires a private deployment repository. Restrict its `APP-SERVICE` environment to the trusted release branch. Add `GH_RUNNER_ADMIN_TOKEN` as a secret scoped to that repository (fine-grained token with repository Administration: read/write) and `AZURE_RUNNER_SSH_PUBLIC_KEY` as an environment variable. Specify only a public SSH key.
* For VNET, use [workload identity federation](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-azure). Bind the Azure identity to the private repository's exact `APP-SERVICE` subject, including the immutable owner and repository IDs for new repositories. Set `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and the DBA group's `AZURE_DBA_GROUP_ID` as environment variables. This avoids an Azure client secret and lets the infrastructure workflow use the group ID without querying the directory. The private release runner continues to use its VM identity.
* Grant the CI identity only the Azure permissions required by the approved deployment scope. The infrastructure workflow needs to provision the configured resource groups and their resources and assign roles within them. Creating an Entra identity or federated credential does not grant those permissions.
* For the legacy login path, store service principal JSON as the `AZURE_CREDENTIALS` environment secret. The hosted Classic and Managed Identities code deployments and the optional cleanup still use it. If it reports `AADSTS5000224`, the configured tenant is unavailable; use a valid identity in the deployment subscription's tenant.
* The [App Service infrastructure workflow](../../.github/workflows/cicd-app-service-infra.yml) compiles its Bicep templates on relevant pushes and on manual runs with **deploy** unchecked. To diagnose the existing Azure sign-in without provisioning, manually enable **check_credentials** and leave **deploy** unchecked.
* To provision infrastructure, run *Actions -> cicd-app-service-infra* manually, check **deploy**, and select `CLASSIC`, `MANAGED_IDENTITIES`, or `VNET`. Leave **run_cleanup** unchecked unless you intend to delete the existing app resource group and purge its Key Vault.
* The [code workflow](../../.github/workflows/cicd-app-service.yml) tests and packages the app on relevant pushes. For a release, run *Actions → cicd-app-service* manually with **deploy** enabled. Before publishing, it creates the database if absent, checks the schema, and ensures the application roles have the required access. Existing data is not reset.
* `CLASSIC` and `MANAGED_IDENTITIES` release from a hosted runner with a temporary PostgreSQL firewall rule. `VNET` uses the [private runner provisioned by the infrastructure workflow](app-service-mi-vnet.md) for both database setup and publishing. No public PostgreSQL firewall rule is used for `VNET`.
* Open the app's URL (```https://${AZURE_APP_NAME}.azurewebsites.net/```) in the browser and test it by creating and reviewing tasks
* Explore the SCM console on (```https://${AZURE_APP_NAME}.scm.azurewebsites.net/```); check logs and bash
* Delete created resources by running *Actions->Cleanup*
