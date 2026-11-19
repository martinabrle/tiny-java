# Spring Boot Todo App

##  Running Todo App on different Azure services (PaaS):
* [AppService deployments](./docs/app-service/)
* [Container instances](./docs/container-instance/)

## Running locally without Azure

With JDK 11, run from the repository root in PowerShell:

```powershell
Set-Location .\todo
$env:SPRING_PROFILES_ACTIVE = 'local'
$env:PORT = '8080'
.\mvnw.cmd spring-boot:run
```

In Bash, run `cd todo` and then `SPRING_PROFILES_ACTIVE=local PORT=8080 ./mvnw spring-boot:run`.
Open http://localhost:8080. The `local` profile uses in-memory H2; changes are lost on restart.
To run the tests, replace `spring-boot:run` with `test`.

The REST API accepts partial updates at `PATCH /api/todos/{id}` and `PATCH /api/todos/`.
The URL identifies a single Todo; if the request body also includes an `id`, it must match.
Bulk updates require one unique `id` per item and return the resulting Todos in request order, including unchanged items.
Omitted fields are left unchanged. Setting `completed` to `true` records a completion time only if one does not already exist;
`false` clears it. For timestamp-based clients, an explicitly supplied `completedDateTime` is honored when `completed` is not set.

##  Running Todo App on the local computer (with Postgresql in Azure):

Before starting, make sure that you have Azure CLI and Java installed on your computer:
* [How to install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
* [Microsoft Build OpenJDK™](https://www.microsoft.com/openjdk)

* Start the command line, clone the repo using ```git clone https://github.com/martinabrle/tiny-java.git``` and change your current directory to ```todo``` sub-dir

* Log in into Azure from the command line using ```az login``` ([link](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli))

* List available Azure subscriptions using ```az account list -o table``` ([link](https://docs.microsoft.com/en-us/cli/azure/account#az-account-list))

* Select an Azure subscription to deploy the database into ```az account set -s 00000000-0000-0000-0000-000000000000```
  ([link](https://docs.microsoft.com/en-us/cli/azure/account#az-account-set)); replace ```00000000-0000-0000-0000-000000000000``` with your Azure subscription Id

* Create a new resource group ```az group create -l eastus -n {YOUR_RG_NAME_rg} --tags CostCentre=DEV DeleteNightly=true```; replace ```eastus``` with the region you are deploying to and ```{YOUR_RG_NAME_rg}``` with a resource group name, unique to your subscription ([link](https://docs.microsoft.com/en-us/cli/azure/group#az-group-create)).

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
  GRANT SELECT, INSERT, UPDATE, DELETE ON todo TO {your_app_user_name};
  ```

* Close the psql session by running ```\q``` in psql

* Set and export environment variables to run the application
   * UNIX Shell:
      ```
      export SPRING_PROFILES_ACTIVE=prod
      export PORT=8080
      export SPRING_DATASOURCE_URL="jdbc:postgresql://{PGSQL_SERVER_NAME}.postgres.database.azure.com:5432/tododb"
      export SPRING_DATASOURCE_USERNAME={your_app_user_name}
      export SPRING_DATASOURCE_PASSWORD={your_app_user_password}
      export SPRING_DATASOURCE_SHOW_SQL=true
      ```
    * PowerShell:
      ```powershell
      $env:SPRING_PROFILES_ACTIVE = 'prod'
      $env:PORT = '8080'
      $env:SPRING_DATASOURCE_URL = 'jdbc:postgresql://{PGSQL_SERVER_NAME}.postgres.database.azure.com:5432/tododb'
      $env:SPRING_DATASOURCE_USERNAME = '{your_app_user_name}'
      $env:SPRING_DATASOURCE_PASSWORD = '{your_app_user_password}'
      $env:SPRING_DATASOURCE_SHOW_SQL = 'true'
      ```

* Run the Todo app on http://localhost:8080 using `./mvnw spring-boot:run` in Bash or `.\mvnw.cmd spring-boot:run` in PowerShell.

* Test it by opening the URL http://localhost:8080 in your browser and creating a few tasks

* Close the app by pressing ```CTRL+C```

* Delete previously created resources using ```az group delete -n {YOUR_RG_NAME_rg}``` ([link](https://docs.microsoft.com/en-us/cli/azure/group?view=azure-cli-latest#az-group-delete))
