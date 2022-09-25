# Spring Boot Todo App

##  Running Todo App to different Azure services:
* [AppService deployments](./docs/app-service/)
* [Container instances](./docs/container-instances/)
* [Azure Spring Apps](./docs/spring-apps/)

##  Running Todo App on the local computer (with Postgresql in Azure):

Before starting, make sure that you have Azure CLI and Java installed on your computer:
* [How to install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
* [Microsoft Build OpenJDK™](https://www.microsoft.com/openjdk)

* Start the command line, clone the repo using ```git clone https://github.com/martinabrle/tiny-java.git``` and change your current directory to ```todo``` sub-dir

* Log in into Azure from the command line using ```az login``` ([link](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli))

* List available Azure subscriptions using ```az account list -o table``` ([link](https://docs.microsoft.com/en-us/cli/azure/account#az-account-list))

* Select an Azure subscription to deploy the database into ```az account set -s 00000000-0000-0000-0000-000000000000```
  ([link](https://docs.microsoft.com/en-us/cli/azure/account#az-account-set)); replace ```00000000-0000-0000-0000-000000000000``` with your Azure subscription Id

* Create a new resource group ```az group create -l eastus -n {YOUR_RG_NAME_rg}  tagsArray='{ "CostCentre": "DEV", "DeleteNightly": "true" }' ```; replace ```eastus``` with the region you are deploying to and ```{YOUR_RG_NAME_rg}``` with a resource group name, unique to your subscription ([link](https://docs.microsoft.com/en-us/cli/azure/group#az-group-create)); 

* Generate a one time strong password, for example using ```openssl rand -base64 24```  (can be re-set from portal later, if needed)

* Create a new flexible PostgreSQL server ```az postgres flexible-server create --name {PGSQL_SERVER_NAME} -g {YOUR_RG_NAME_rg} -l eastus --admin-user {your_admin_name} --admin-password {your_admin_password} --tier Burstable --sku-name Standard_B2s``` ([link](https://docs.microsoft.com/en-us/cli/azure/postgres/flexible-server#az-postgres-flexible-server-create)) and choose yes to allow your current IP to go through Postgresql's firewall

* Create a ```tododb``` database using ```az postgres flexible-server db create --resource-group {YOUR_RG_NAME_rg} --server-name {PGSQL_SERVER_NAME} --database-name tododb``` ([link](https://docs.microsoft.com/en-us/cli/azure/postgres/flexible-server/db#az-postgres-flexible-server-db-create))

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
