# Spring Boot Todo App
Before starting, make sure that you have Azure CLI and Java installed on your computer:
* [How to install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
* [Microsoft Build OpenJDK™](https://www.microsoft.com/openjdk)

### Running Todo App on your computer
* Start the command line, clone the repo using ```git clone https://github.com/martinabrle/tiny-java.git``` and change your current directory to ```todo``` sub-dir
* Log in into Azure from the command line using ```az login``` [(link)](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli)
* List available Azure subscriptions using ```az account list -o table``` [(link)](https://docs.microsoft.com/en-us/cli/azure/account#az-account-list)
* Select an Azure subscription to deploy the database into ```az account set -s 00000000-0000-0000-0000-000000000000```
  [(link)](https://docs.microsoft.com/en-us/cli/azure/account#az-account-set); replace ```00000000-0000-0000-0000-000000000000``` with your Azure subscription Id
* Create a new resource group ```az group create -l eastus -n MY_RG_NAME_rg```; replace ```eastus``` with the region you are deploying to and ```MY_RG_NAME_rg``` with a resource group name, unique to your subscription [(link)](https://docs.microsoft.com/en-us/cli/azure/group#az-group-create); 
* Generate a one time strong password, for example using ```openssl rand -base64 24```  (can be re-set from portal later, if needed)
* Create a new flexible PostgreSQL server ```az postgres flexible-server create --name MY_UNIQUE_DNS_SERVER_NAME -g MY_RG_NAME_rg -l eastus --admin-user {your_admin_name} --admin-password {your_password} --tier Burstable --sku-name Standard_B2s``` [(link)](https://docs.microsoft.com/en-us/cli/azure/postgres/flexible-server#az-postgres-flexible-server-create) and choose yes to add the current IP into firewall
* Create a ```tododb``` database using ```az postgres flexible-server db create --resource-group MY_RG_NAME_rg --server-name MY_UNIQUE_DNS_SERVER_NAME --database-name tododb``` [(link)](https://docs.microsoft.com/en-us/cli/azure/postgres/flexible-server/db#az-postgres-flexible-server-db-create)
* Connect to the newly created server using ```psql "host=MY_UNIQUE_DNS_SERVER_NAME.postgres.database.azure.com port=5432 dbname=tododb user={your_admin_name} password={your_password} sslmode=require"```
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
* Set and export environment variables to run the application
   * UNIX Shell:
      ```
      export SPRING_DATASOURCE_URL="jdbc:postgresql://MY_UNIQUE_DNS_SERVER_NAME.postgres.database.azure.com:5432/tododb"
      export SPRING_DATASOURCE_USERNAME={your_app_user_name}
      export SPRING_DATASOURCE_PASSWORD={your_app_user_password}
      export SPRING_DATASOURCE_SHOW_SQL=true
      ```
    * CMD or PowerShell:
      ```
      set SPRING_DATASOURCE_URL="jdbc:postgresql://MY_UNIQUE_DNS_SERVER_NAME.postgres.database.azure.com:5432/tododb"
      set SPRING_DATASOURCE_USERNAME={your_app_user_name}
      set SPRING_DATASOURCE_PASSWORD={your_app_user_password}
      set SPRING_DATASOURCE_SHOW_SQL=true
* Run the Todo app on http://localhost:8080 using ```./mvnw spring-boot:run```
* Test it by opening the URL http://localhost:8080 in your browser and creating a few tasks
* Close the app by pressing ```CTRL+C```
* Delete previously created resources ```az group delete -n MY_RG_NAME_rg```
  (https://docs.microsoft.com/en-us/cli/azure/group?view=azure-cli-latest#az-group-delete)

### Running todo app in AppService on Azure using CLI
* Follow all the steps described in [Running Todo App on your computer](https://github.com/martinabrle/tiny-java#running-todo-app-on-your-computer), test the application but do not delete resource group in the end
* Create a new AppService plan using ```az ...```
* Create a new AppService on the previously created AppService plan using ```az ...``` and write down the URL
* Configure
* Deploy the application
* Open the app's URL in the browser and test it by creating a few tasks
* Explore the SCM console on 



### Running todo app in AppService on Azure using a Bicep template

