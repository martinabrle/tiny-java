# Spring Boot Todo App on App Service
## Basic, simplified deployment using AZ CLI

![Architecture Diagram](../../diagrams/tiny-java-app-service-basic.png)

* Start the command line, clone the repo using ```git clone https://github.com/martinabrle/tiny-java.git``` and change your current directory to ```tiny-java/scripts``` directory:
    ```
    cd ./tiny-java/scripts
    ```

* Log in into Azure from the command line using ```az login``` ([link](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli))

* List available Azure subscriptions using ```az account list -o table``` ([link](https://docs.microsoft.com/en-us/cli/azure/account#az-account-list))

* Select an Azure subscription to deploy the infra into, using ```az account set -s 00000000-0000-0000-0000-000000000000```
  ([link](https://docs.microsoft.com/en-us/cli/azure/account#az-account-set)); replace ```00000000-0000-0000-0000-000000000000``` with Azure subscription Id you will deploy into

* Set environment variables:
    ```
    export ENV_PREFIX="{{{REPLACE_WITH_DEPLOYMENT_PREFIX}}}"
    ```

    ```
    export AZURE_RESOURCE_GROUP=${ENV_PREFIX}-tinyjava-app-svc_rg
    export AZURE_LOCATION=eastus
    export AZURE_DB_SERVER_NAME=${ENV_PREFIX}-tinyjava-app-svc-pg
    export AZURE_DB_NAME=tododb
    export dbAdminName="a`openssl rand -hex 5`"
    export dbAdminPassword="`openssl rand -base64 25`#@"
    export AZURE_DB_APP_USER_NAME="u`openssl rand -hex 5`"
    export AZURE_DB_APP_USER_PASSWORD="`openssl rand -base64 25`#@"
    export AZURE_APP_NAME=${ENV_PREFIX}-tinyjava-app-svc
    export AZURE_APP_PORT=443
    export clientIPAddress=`dig +short myip.opendns.com @resolver1.opendns.com.`

    echo "-------------------"
    echo "Save for later use:"
    echo "-------------------"
    echo "DB Admin: ${dbAdminName}"
    echo "DB Admins password: ${dbAdminPassword}"
    echo "DB App user: ${AZURE_DB_APP_USER_NAME}"
    echo "DB App users password: ${AZURE_DB_APP_USER_PASSWORD}"   
    ```

* Create a new flexible PostgreSQL server ```az postgres flexible-server create --name $AZURE_DB_SERVER_NAME -g $AZURE_RESOURCE_GROUP -l eastus --admin-user $dbAdminName --admin-password $dbAdminPassword --tier Burstable --sku-name Standard_B2s``` ([link](https://docs.microsoft.com/en-us/cli/azure/postgres/flexible-server#az-postgres-flexible-server-create)) and choose yes to allow your current IP to go through Postgresql's firewall

* Create the app database using ```az postgres flexible-server db create --resource-group $AZURE_RESOURCE_GROUP --server-name $AZURE_DB_SERVER_NAME --database-name $AZURE_DB_NAME``` ([link](https://docs.microsoft.com/en-us/cli/azure/postgres/flexible-server/db#az-postgres-flexible-server-db-create))

* Connect to the the newly created Postgresql database:
    ```
    psql "host=${AZURE_DB_SERVER_NAME}.postgres.database.azure.com port=5432 dbname=${AZURE_DB_NAME} user=${AZURE_DB_APP_USER_NAME}@${AZURE_DB_SERVER_NAME} password=${dbAdminPassword} sslmode=require"
    ```

* Initialize DB schema:
    ```
    CREATE TABLE IF NOT EXISTS todo (
        "id" UUID DEFAULT gen_random_uuid() PRIMARY KEY NOT NULL,
        "todo_text" VARCHAR(255) NOT NULL,
        "created_date_time" TIMESTAMP DEFAULT NOW()::date,
        "completed_date_time" TIMESTAMP DEFAULT NULL
    );
    ```

* Create an App DB user and assign their rights:
    ```
    CREATE USER ${AZURE_DB_APP_USER_NAME} WITH PASSWORD '${AZURE_DB_APP_USER_PASSWORD}';
    GRANT CONNECT ON DATABASE tododb TO ${AZURE_DB_APP_USER_NAME};
    GRANT USAGE ON SCHEMA public TO ${AZURE_DB_APP_USER_NAME};
    GRANT SELECT ON todo TO ${AZURE_DB_APP_USER_NAME};
    GRANT INSERT ON todo TO ${AZURE_DB_APP_USER_NAME};
    ```

* Change your current directory to ```tiny-java/todo```:
    ```
    cd ../todo
    ```

* List all available runtimes for running Todo App on Linux with ```az webapp list-runtimes --linux```, here we will be using ```JAVA:11-java11```. Make sure that you have the right subscription selected as your default, available runtimes may differ by regions

* Create a new AppService plan using ```az appservice plan create -g $AZURE_RESOURCE_GROUP -n "${AZURE_APP_NAME}-plan" --is-linux --sku S1 --location eastus```

* Create a new AppService on the previously created AppService plan using ```az webapp create --name $AZURE_APP_NAME --plan "${AZURE_APP_NAME}-plan" --resource-group $AZURE_RESOURCE_GROUP --runtime "JAVA|11-java11"```. ```${AZURE_APP_NAME}``` is a part of the app's FQDN and must be unique.

* Configure app's parameters by running
  ```
  az webapp config appsettings set -g $AZURE_RESOURCE_GROUP -n $AZURE_APP_NAME --settings SPRING_DATASOURCE_URL="jdbc:postgresql://${AZURE_DB_SERVER_NAME}.postgres.database.azure.com:5432/${AZURE_DB_NAME}"
  az webapp config appsettings set -g $AZURE_RESOURCE_GROUP -n $AZURE_APP_NAME --settings SPRING_DATASOURCE_USERNAME=$AZURE_DB_APP_USER_NAME
  az webapp config appsettings set -g $AZURE_RESOURCE_GROUP -n $AZURE_APP_NAME --settings SPRING_DATASOURCE_PASSWORD=$AZURE_DB_APP_USER_PASSWORD
  az webapp config appsettings set -g $AZURE_RESOURCE_GROUP -n $AZURE_APP_NAME --settings SPRING_DATASOURCE_SHOW_SQL=true
  ```

*  Build the app using ```./mvnw clean``` and ```./mvnw build```

* Configure the application with Maven Plugin by running ```./mvnw com.microsoft.azure:azure-webapp-maven-plugin:2.2.0:config```. This maven goal will first authenticate with Azure and than it will ask you which App Service (or in other words, which Java WebApp) do you want to deploy the app into. Confirm the selection and you will find an updated configuration in the project's ```pom.xml```.

* Deploy the application by running ```./mvnw azure-webapp:deploy```

* Open the app's URL ```https://${AZURE_APP_NAME}.azurewebsites.net/``` in the browser and test it by creating and reviewing tasks

* Explore the SCM console on ```https://${AZURE_APP_NAME}.scm.azurewebsites.net/```

* Delete previously created resources using ```az group delete -n $AZURE_RESOURCE_GROUP``` ([link](https://docs.microsoft.com/en-us/cli/azure/group?view=azure-cli-latest#az-group-delete))
