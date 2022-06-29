# Spring Boot Todo App
Before starting, make sure that you have Azure CLI and Java installed on your computer:
* [How to install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
* [Microsoft Build OpenJDK™](https://www.microsoft.com/openjdk)

### Running Todo App on your computer (with Postgresql in Azure)
* Start the command line, clone the repo using ```git clone https://github.com/martinabrle/tiny-java.git``` and change your current directory to ```todo``` sub-dir
* Log in into Azure from the command line using ```az login``` [(link)](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli)
* List available Azure subscriptions using ```az account list -o table``` [(link)](https://docs.microsoft.com/en-us/cli/azure/account#az-account-list)
* Select an Azure subscription to deploy the database into ```az account set -s 00000000-0000-0000-0000-000000000000```
  [(link)](https://docs.microsoft.com/en-us/cli/azure/account#az-account-set); replace ```00000000-0000-0000-0000-000000000000``` with your Azure subscription Id
* Create a new resource group ```az group create -l eastus -n {YOUR_RG_NAME_rg}  tagsArray='{ "CostCentre": "DEV", "DeleteNightly": "true" }' ```; replace ```eastus``` with the region you are deploying to and ```{YOUR_RG_NAME_rg}``` with a resource group name, unique to your subscription [(link)](https://docs.microsoft.com/en-us/cli/azure/group#az-group-create); 
* Generate a one time strong password, for example using ```openssl rand -base64 24```  (can be re-set from portal later, if needed)
* Create a new flexible PostgreSQL server ```az postgres flexible-server create --name {PGSQL_SERVER_NAME} -g {YOUR_RG_NAME_rg} -l eastus --admin-user {your_admin_name} --admin-password {your_admin_password} --tier Burstable --sku-name Standard_B2s``` [(link)](https://docs.microsoft.com/en-us/cli/azure/postgres/flexible-server#az-postgres-flexible-server-create) and choose yes to allow your current IP to go through Postgresql's firewall
* Create a ```tododb``` database using ```az postgres flexible-server db create --resource-group {YOUR_RG_NAME_rg} --server-name {PGSQL_SERVER_NAME} --database-name tododb``` [(link)](https://docs.microsoft.com/en-us/cli/azure/postgres/flexible-server/db#az-postgres-flexible-server-db-create)
* Connect to the newly created server using ```psql "host={PGSQL_SERVER_NAME}.postgres.database.azure.com port=5432 dbname=tododb user={your_admin_name} password={your_admin_password} sslmode=require"```
* Create database schema
  ```
  CREATE TABLE IF NOT EXISTS todo (
      "id" UUID DEFAULT gen_random_uuid() PRIMARY KEY NOT NULL,
      "todo_text" VARCHAR(255) NOT NULL,
      "created_date_time" TIMESTAMP DEFAULT NOW()::date,
      "completed_date_time" TIMESTAMP DEFAULT NULL
  );
  ```
* Load demo data
  ```INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000001','Create Stark Enterprises','2011-12-30 15:27:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000002','Invent the first Iron Man Suit','2012-03-08 13:53:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000003','Become a Hero','2013-01-08 15:14:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000004','Help build S.H.I.E.L.D.','2013-12-03 12:59:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000005','Form the Avengers','2015-02-23 11:09:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000006','Put Hawkeye on the right path','2017-03-22 14:51:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000007','Make Stark Industries a massive success','2018-04-16 12:05:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000008','Keep escaping death in the most Tony Stark way possible','2019-04-11 14:08:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000009','Learn Spring boot','2019-11-21 10:44:00-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000010','Deploy a multi tier Spring boot app into Azure','2022-04-22 19:10:25-07') ON CONFLICT DO NOTHING;
  ```
* Create an application user and grant appropriate permissions
  ```
  CREATE USER {your_app_user_name} WITH PASSWORD '{your_app_user_password}';
  GRANT CONNECT ON DATABASE tododb TO {your_app_user_name};
  GRANT USAGE ON SCHEMA public TO {your_app_user_name};
  GRANT SELECT ON todo TO {your_app_user_name};
  GRANT INSERT ON todo TO {your_app_user_name};   
  ```
* Close the psql session by running ```\q``` in psql
* Set and export environment variables to run the application
   * UNIX Shell:
      ```
      export SPRING_DATASOURCE_URL="jdbc:postgresql://{PGSQL_SERVER_NAME}.postgres.database.azure.com:5432/tododb"
      export SPRING_DATASOURCE_USERNAME={your_app_user_name}
      export SPRING_DATASOURCE_PASSWORD={your_app_user_password}
      export SPRING_DATASOURCE_SHOW_SQL=true
      ```
    * CMD or PowerShell:
      ```
      set SPRING_DATASOURCE_URL="jdbc:postgresql://{PGSQL_SERVER_NAME}.postgres.database.azure.com:5432/tododb"
      set SPRING_DATASOURCE_USERNAME={your_app_user_name}
      set SPRING_DATASOURCE_PASSWORD={your_app_user_password}
      set SPRING_DATASOURCE_SHOW_SQL=true

* Run the Todo app on http://localhost:8080 using ```./mvnw spring-boot:run```
* Test it by opening the URL http://localhost:8080 in your browser and creating a few tasks
* Close the app by pressing ```CTRL+C```
* Delete previously created resources using ```az group delete -n {YOUR_RG_NAME_rg}``` ([link](https://docs.microsoft.com/en-us/cli/azure/group?view=azure-cli-latest#az-group-delete))

### Running Todo App in an AppService on Azure: deployment using AZ CLI
(we are not using Azure KeyVault in this example due to time constraints)
* Follow all the steps described in [Running Todo App on your computer](https://github.com/martinabrle/tiny-java#running-todo-app-on-your-computer), test the application but do not delete the resource group ```{YOUR_RG_NAME_rg}``` in the end
* First list all available runtimes for running Todo App on Linux with ```az webapp list-runtimes --linux```, here we will be using ```JAVA:11-java11```. Make sure that you have the right subscription selected as your default, available runtimes may differ by regions
* Create a new AppService plan using ```az appservice plan create -g {YOUR_RG_NAME_rg} -n {YOUR_APPSERVICE_PLAN_NAME} --is-linux --sku S1 --location eastus```
* Create a new AppService on the previously created AppService plan using ```az webapp create --name {YOUR_APPSERVICE_NAME} --plan {YOUR_APPSERVICE_PLAN_NAME} --resource-group {YOUR_RG_NAME_rg} --runtime "JAVA|11-java11"```. ```{YOUR_APPSERVICE_NAME}``` is a part of the app's FQDN and must be unique.
* Configure app's parameters by running
  ```
  az webapp config appsettings set -g {YOUR_RG_NAME_rg} -n {YOUR_APPSERVICE_NAME} --settings SPRING_DATASOURCE_URL="jdbc:postgresql://{PGSQL_SERVER_NAME}.postgres.database.azure.com:5432/tododb"

  az webapp config appsettings set -g {YOUR_RG_NAME_rg} -n {YOUR_APPSERVICE_NAME} --settings SPRING_DATASOURCE_USERNAME=
  {your_app_user_name}
  az webapp config appsettings set -g {YOUR_RG_NAME_rg} -n {YOUR_APPSERVICE_NAME} --settings SPRING_DATASOURCE_PASSWORD=
  {your_app_user_password}
  az webapp config appsettings set -g {YOUR_RG_NAME_rg} -n {YOUR_APPSERVICE_NAME} --settings SPRING_DATASOURCE_SHOW_SQL=true
  ```
*  Build the app using ```./mvnw clean``` and ```./mvnw build```
* Configure the application with Maven Plugin by running ```./mvnw com.microsoft.azure:azure-webapp-maven-plugin:2.2.0:config```. This maven goal will first authenticate with Azure and than it will ask you which App Service (or in other words, which Java WebApp) do you want to deploy the app into. Confirm the selection and you will find an updated configuration in the project's ```pom.xml```.
* Deploy the application by running ```./mvnw azure-webapp:deploy```
* Open the app's URL (https://{YOUR_APPSERVICE_NAME}.azurewebsites.net/) in the browser and test it by creating and reviewing tasks
* Explore the SCM console on (https://{YOUR_APPSERVICE_NAME}.scm.azurewebsites.net/)
* Delete previously created resources using ```az group delete -n {YOUR_RG_NAME_rg}``` ([link](https://docs.microsoft.com/en-us/cli/azure/group?view=azure-cli-latest#az-group-delete))

### Running Todo App in an AppService on Azure: deployment using AZ CLI and Bicep template
(we are deploying Azure KeyVault to manage secrets, but skipping Log Analytics and AppInsights to reduce App and Bicep template complexity)
* Log in into Azure from the command line using ```az login``` [(link)](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli)
* List available Azure subscriptions using ```az account list -o table``` [(link)](https://docs.microsoft.com/en-us/cli/azure/account#az-account-list)
* Select an Azure subscription to deploy the database into ```az account set -s 00000000-0000-0000-0000-000000000000```
  [(link)](https://docs.microsoft.com/en-us/cli/azure/account#az-account-set); replace ```00000000-0000-0000-0000-000000000000``` with your Azure subscription Id
* Change the current directory into ```./scripts``` sub-dir
* Deploy the app using a Bicep script
```
 az deployment group create --resource-group {YOUR_RG_NAME_rg} --template-file ./app-service.bicep \
                        --parameters keyVaultName={YOUR_KEY_VAULT_NAME}  \
                                     dbServerName={PGSQL_SERVER_NAME} \
                                     dbName=tododb \
                                     dbAdminName={your_admin_name} \
                                     dbAdminPassword={your_admin_password} \
                                     dbUserName={your_app_user_name} \
                                     dbUserPassword={your_app_user_password} \
                                     appServiceName={YOUR_APPSERVICE_NAME} \
                                     appServicePort=443 \
                                     clientIPAddress={YOUR_IP_FOR_FIREWALL_EXCEPTION}
```
* Validate that an App Service, App Service Plan, Key Vault and a Postgresql flexible server has been created.
* Connect to the newly created server using ```psql "host={PGSQL_SERVER_NAME}.postgres.database.azure.com port=5432 dbname=tododb user={your_admin_name} password={your_admin_password} sslmode=require"```
* Create database schema
  ```
  CREATE TABLE IF NOT EXISTS todo (
      "id" UUID DEFAULT gen_random_uuid() PRIMARY KEY NOT NULL,
      "todo_text" VARCHAR(255) NOT NULL,
      "created_date_time" TIMESTAMP DEFAULT NOW()::date,
      "completed_date_time" TIMESTAMP DEFAULT NULL
  );
  ```
* Load demo data
  ```INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000001','Create Stark Enterprises','2011-12-30 15:27:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000002','Invent the first Iron Man Suit','2012-03-08 13:53:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000003','Become a Hero','2013-01-08 15:14:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000004','Help build S.H.I.E.L.D.','2013-12-03 12:59:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000005','Form the Avengers','2015-02-23 11:09:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000006','Put Hawkeye on the right path','2017-03-22 14:51:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000007','Make Stark Industries a massive success','2018-04-16 12:05:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000008','Keep escaping death in the most Tony Stark way possible','2019-04-11 14:08:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000009','Learn Spring boot','2019-11-21 10:44:00-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000010','Deploy a multi tier Spring boot app into Azure','2022-04-22 19:10:25-07') ON CONFLICT DO NOTHING;
  ```
* Create an application user and grant appropriate permissions
  ```
  CREATE USER {your_app_user_name} WITH PASSWORD '{your_app_user_password}';
  GRANT CONNECT ON DATABASE tododb TO {your_app_user_name};
  GRANT USAGE ON SCHEMA public TO {your_app_user_name};
  GRANT SELECT ON todo TO {your_app_user_name};
  GRANT INSERT ON todo TO {your_app_user_name};   
  ```
* Close the psql session by running ```\q``` in psql
* Build the app using ```./mvnw clean``` and ```./mvnw build```
* Configure the application with Maven Plugin by running ```./mvnw com.microsoft.azure:azure-webapp-maven-plugin:2.2.0:config```. This maven goal will first authenticate with Azure and than it will ask you which App Service (or in other words, which Java WebApp) do you want to deploy the app into. Confirm the selection and you will find an updated configuration in the project's ```pom.xml```.
* Deploy the application by running ```./mvnw azure-webapp:deploy```
* WARNING: Maven add-in sometimes does not overwrite ```<appServicePlanName>``` and ```<appServicePlanResourceGroup>``` after these been filled in. Solution is either to clear those values manually, or replace whatever is in there with right values (```{YOUR_APPSERVICE_NAME}-plan``` for ```<appServicePlanName>``` and ```{YOUR_RG_NAME_rg}``` for ```<appServicePlanResourceGroup>```; ```{YOUR_APPSERVICE_NAME}-plan``` is the name automatically generated in the Bicep script
* Open the app's URL (https://{YOUR_APPSERVICE_NAME}.azurewebsites.net/) in the browser and test it by creating and reviewing tasks
* Explore the SCM console on (https://{YOUR_APPSERVICE_NAME}.scm.azurewebsites.net/)
* Delete previously created resources using ```az group delete -n {YOUR_RG_NAME_rg}``` ([link](https://docs.microsoft.com/en-us/cli/azure/group?view=azure-cli-latest#az-group-delete))

### Running Todo App in a Spring Apps cluster on Azure: deployment using AZ CLI and Bicep templates
(we are deploying Azure KeyVault to manage secrets, and also deploy Log Analytics and AppInsights to to provide a more realistic example. Log analytics is deployed into another resource group as this is a resource you will typically wan to share this resource between many workloads in the same geography. We will be using a parameters file for the deployment - DO NOT CHECK THIS ONE IN into your source code repo as it will contain secrets)
* Log in into Azure from the command line using ```az login``` [(link)](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli)
* List available Azure subscriptions using ```az account list -o table``` [(link)](https://docs.microsoft.com/en-us/cli/azure/account#az-account-list)
* Select an Azure subscription to deploy the database into ```az account set -s 00000000-0000-0000-0000-000000000000```
  [(link)](https://docs.microsoft.com/en-us/cli/azure/account#az-account-set); replace ```00000000-0000-0000-0000-000000000000``` with your Azure subscription Id
* Change the current directory into ```./scripts``` sub-dir
* Create a new resource group for Log Analytics```az group create -l eastus -n {YOUR_LOGS_RG_NAME_rg}  tagsArray='{ "CostCentre": "DEV", "DeleteNightly": "true" }' ```; replace ```eastus``` with the region you are deploying to and ```{YOUR_LOGS_RG_NAME_rg}``` with a resource group name, unique to your subscription [(link)](https://docs.microsoft.com/en-us/cli/azure/group#az-group-create)

* Deploy Log Analytics using a Bicep template by running  
  ```
  az deployment group create --resource-group {YOUR_LOGS_RG_NAME_rg} --template-file ./templates/components/logs.bicep \
              --parameters location=eastus  \
                            logAnalyticsWorkspaceName={YOUR_LOGS_WORKSPACE_ANALYTICS_NAME}
  ```


* Create a new resource group ```az group create -l eastus -n {YOUR_RG_NAME_rg}  tagsArray='{ "CostCentre": "DEV", "DeleteNightly": "true" }' ```; replace ```eastus``` with the region you are deploying to and ```{YOUR_RG_NAME_rg}``` with a resource group name, unique to your subscription  [(link)](https://docs.microsoft.com/en-us/cli/azure/group#az-group-create); 

* Modify the ```parameters.json``` and fill in all the parameters. Easiest way to generate strong passwords on your computer is by using ```openssl rand -base64 26```; and you can also use it to generate unique user names and passwords
* Now we need to use a workaround due to an issue with the current Bicep version and first transpile Bicep into ARM. Run ```az bicep build --file .\spring-apps.bicep``` to generate an ARM template from our Bicep tamplate 
* Deploy all the resources into the previously created resource group by running ```az group deployment create -g {YOUR_RG_NAME_rg} --template-file .\spring-apps.json --parameters .\parameters.json```
* Connect to the newly created server using ```psql "host={PGSQL_SERVER_NAME}.postgres.database.azure.com port=5432 dbname=tododb user={your_admin_name} password={your_admin_password} sslmode=require"```
* Create database schema
  ```
  CREATE TABLE IF NOT EXISTS todo (
      "id" UUID DEFAULT gen_random_uuid() PRIMARY KEY NOT NULL,
      "todo_text" VARCHAR(255) NOT NULL,
      "created_date_time" TIMESTAMP DEFAULT NOW()::date,
      "completed_date_time" TIMESTAMP DEFAULT NULL
  );
  ```
* Load demo data
  ```INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000001','Create Stark Enterprises','2011-12-30 15:27:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000002','Invent the first Iron Man Suit','2012-03-08 13:53:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000003','Become a Hero','2013-01-08 15:14:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000004','Help build S.H.I.E.L.D.','2013-12-03 12:59:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000005','Form the Avengers','2015-02-23 11:09:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000006','Put Hawkeye on the right path','2017-03-22 14:51:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000007','Make Stark Industries a massive success','2018-04-16 12:05:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000008','Keep escaping death in the most Tony Stark way possible','2019-04-11 14:08:25-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000009','Learn Spring boot','2019-11-21 10:44:00-07') ON CONFLICT DO NOTHING;
  INSERT INTO todo ("id", "todo_text", "created_date_time") VALUES ('00000000000000000000000000000010','Deploy a multi tier Spring boot app into Azure','2022-04-22 19:10:25-07') ON CONFLICT DO NOTHING;
  ```
* Create an application user and grant appropriate permissions
  ```
  CREATE USER {your_app_user_name} WITH PASSWORD '{your_app_user_password}';
  GRANT CONNECT ON DATABASE tododb TO {your_app_user_name};
  GRANT USAGE ON SCHEMA public TO {your_app_user_name};
  GRANT SELECT ON todo TO {your_app_user_name};
  GRANT INSERT ON todo TO {your_app_user_name};   
  ```
* Close the psql session by running ```\q``` in psql
* Change the directory into ```../todo``` sub-dir
* Build the app using ```./mvnw clean``` and ```./mvnw build```
* Deploy the app using ```az spring app deploy -n {YOUR_APP_NAME} -s {SPRING_APPS_CLUSTER_NAME} -g {YOUR_RG_NAME_rg} --artifact-path target/todo-0.0.1-SNAPSHOT.jar```
* Check the logs using ```az spring app logs --name {YOUR_APP_NAME}``` ; use ``` --follow ``` switch for continuous log streaming
* Test the app by opening https://{SPRING_APPS_CLUSTER_NAME}-{YOUR_APP_NAME}.azuremicroservices.io in your browser

### Bonus: deploying Todo App into a Spring Apps cluster with Github actions (CI/CD Pipeline)
* Copy the repo's content into your personal or organizational GitHub Account
* Open your repository in the browser and select *Settings->Secrets->Actions*
* Set the following GitHub action variables:
```
AZURE_SUBSCRIPTION_ID
AZURE_RESOURCE_GROUP

AZURE_LOCATION

AZURE_KEY_VAULT_NAME

AZURE_LOG_ANALYTICS_WRKSPC_NAME
AZURE_LOG_ANALYTICS_WRKSPC_RESOURCE_GROUP

AZURE_DB_SERVER_NAME
AZURE_DB_NAME

AZURE_DB_APP_USER_NAME
AZURE_DB_APP_USER_PASSWORD

AZURE_DB_APP_USER_NAME
AZURE_DB_APP_USER_PASSWORD

AZURE_SPRING_CLOUD_NAME

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
* This may not be ideal, if you are not using a separated subscription for each workload as a part of your landing zones; the alternative is to modify deployment scripts so that these do not create resource groups and give RBAC contributor, owner and Key Vault administrator roles to the deployment service principal on the reasource group ```{YOUR_RG_NAME_rg}```. However, using a subscription per workload and giving the deployment service principle these roles allows us to have ```{YOUR_RG_NAME_rg}``` only automatically created and deleted. By deleting the resource group, Azure Resource Manager makes sure that resources have been deleted in the right order, otherwise you would have the responsibility  to delete resources in the right order. We should switch here to OICD as described [here](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-azure#use-the-azure-login-action-with-openid-connect) to avoid relying on storing deployment credentials
* Run the infrastructure deployment by running *Actions-cicd-spring-apps-infra* manually; this action is defined in ```./tiny-java/.github/workflows/cicd-spring-apps-infra.yml```
* Run the code deployment by running *Actions->cicd-spring-apps* manually; this action is defined in ```./tiny-java/.github/workflows/cicd-spring-apps.yml```
* Check that all resources have been deployed in Azure portal in the  ```{YOUR_RG_NAME_rg}``` resource group you defined in the parameter file 
* Check the logs using ```az spring app logs --name {YOUR_APPSERVICE_NAME}``` ; use ``` --follow ``` switch for continuous log streaming
* Test the app by opening https://{SPRING_APPS_CLUSTER_NAME}-{YOUR_APPSERVICE_NAME}.azuremicroservices.io in your browser
* Delete created resources by running *Actions->Cleanup*
