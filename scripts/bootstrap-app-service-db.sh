#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
: "${DEPLOYMENT_MODE:?}" "${RESOURCE_GROUP:?}" "${APP_NAME:?}" "${DB_SERVER:?}" "${DB_NAME:?}"

case "$DEPLOYMENT_MODE" in
  CLASSIC|MANAGED_IDENTITIES|VNET) ;;
  *) echo "::error::Unsupported App Service deployment mode: $DEPLOYMENT_MODE"; exit 1 ;;
esac
if [[ ! "$DB_NAME" =~ ^[[:alnum:]_][[:alnum:]_-]{0,62}$ || "$DB_NAME" == 'postgres' || "$DB_NAME" == template* ]]; then
  echo '::error::Set AZURE_DB_NAME to a separate application database name.'
  exit 1
fi

export PGHOST="${DB_SERVER}.postgres.database.azure.com"
export PGCONNECT_TIMEOUT=5 PGSSLMODE=verify-full
export PGSSLROOTCERT="${PGSSLROOTCERT:-/etc/ssl/certs/ca-certificates.crt}"
app_role=${APP_NAME//-/_}
staging_role="${app_role}_staging"
[[ ${#staging_role} -le 63 ]] || { echo "::error::App Service name is too long to derive PostgreSQL roles."; exit 1; }

if [[ "$DEPLOYMENT_MODE" == 'VNET' ]]; then
  : "${RUNNER_DB_ADMIN:?}"
  if ! addresses=$(getent ahostsv4 "$PGHOST" | awk '{ print $1 }' | sort -u) ||
     [[ -z "$addresses" ]] || grep -qv '^10\.0\.4\.[0-9]\{1,3\}$' <<< "$addresses"; then
    echo "::error::$PGHOST did not resolve exclusively to the VNET database subnet."
    exit 1
  fi
  export PGUSER="$RUNNER_DB_ADMIN"
  PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query accessToken -o tsv)
else
  : "${DB_ADMIN_PASSWORD:?Set AZURE_DB_ADMIN_PASSWORD to the PostgreSQL server administrator password.}"
  PGUSER=$(az postgres flexible-server show --resource-group "$RESOURCE_GROUP" \
    --name "$DB_SERVER" --query administratorLogin -o tsv)
  : "${PGUSER:?The PostgreSQL server has no password administrator.}"
  PGPASSWORD=$DB_ADMIN_PASSWORD
fi
: "${PGPASSWORD:?Could not obtain PostgreSQL credentials.}"
export PGUSER PGPASSWORD

psql_cmd=(psql -X -w --set=ON_ERROR_STOP=1)
for attempt in {1..12}; do
  if "${psql_cmd[@]}" --dbname=postgres --tuples-only --command='SELECT 1' > /dev/null; then
    break
  fi
  if [[ "$attempt" -eq 12 ]]; then
    echo "::error::Cannot connect to PostgreSQL as the deployment administrator."
    exit 1
  fi
  sleep 5
done

# CREATE DATABASE cannot run inside a transaction; keep this before the transactional schema and role scripts.
"${psql_cmd[@]}" --dbname=postgres --set=db_name="$DB_NAME" <<'SQL'
SELECT format('CREATE DATABASE %I', :'db_name')
WHERE NOT EXISTS (SELECT FROM pg_catalog.pg_database WHERE datname = :'db_name')
\gexec
SQL
"${psql_cmd[@]}" --dbname="$DB_NAME" --single-transaction --file=./db.sql > /dev/null
"${psql_cmd[@]}" --dbname="$DB_NAME" \
  --command='SELECT id, todo_text, created_date_time, completed_date_time FROM public.todo LIMIT 0' > /dev/null

register_identity() {
  local role=$1 identity=$2
  "${psql_cmd[@]}" --dbname=postgres --set=role_name="$role" \
    --set=principal_id="$identity" --file=./db-entra-role.sql
}

grant_role() {
  "${psql_cmd[@]}" --dbname="$DB_NAME" --set=db_name="$DB_NAME" \
    --set=role_name="$1" --file=./db-grant-todo-role.sql
}

case "$DEPLOYMENT_MODE" in
  VNET)
    app_id=$(az webapp identity show --resource-group "$RESOURCE_GROUP" --name "$APP_NAME" --query principalId -o tsv)
    : "${app_id:?Production App Service has no managed identity.}"
    register_identity "$app_role" "$app_id"
    grant_role "$app_role"
    ;;
  MANAGED_IDENTITIES)
    : "${DBA_GROUP_NAME:?Set AZURE_DBA_GROUP_NAME for the Entra role setup.}"
    app_id=$(az webapp identity show --resource-group "$RESOURCE_GROUP" --name "$APP_NAME" --query principalId -o tsv)
    staging_id=$(az webapp identity show --resource-group "$RESOURCE_GROUP" --name "$APP_NAME" --slot staging --query principalId -o tsv)
    : "${app_id:?Production has no managed identity.}" "${staging_id:?Staging has no managed identity.}"
    entra_token=$(az account get-access-token --resource-type oss-rdbms --query accessToken -o tsv)
    : "${entra_token:?Could not obtain a PostgreSQL Entra token.}"
    PGUSER="$DBA_GROUP_NAME" PGPASSWORD="$entra_token" register_identity "$app_role" "$app_id"
    PGUSER="$DBA_GROUP_NAME" PGPASSWORD="$entra_token" register_identity "$staging_role" "$staging_id"
    grant_role "$app_role"
    grant_role "$staging_role"
    ;;
  CLASSIC)
    : "${VAULT_NAME:?}"
    for role in "$app_role" "$staging_role"; do
      secret_name=SPRING-DATASOURCE-PASSWORD
      if [[ "$role" == "$staging_role" ]]; then
        secret_name+=-STAGING
      fi
      role_password=$(az keyvault secret show --vault-name "$VAULT_NAME" --name "$secret_name" --query value -o tsv)
      : "${role_password:?The Key Vault application password is missing.}"
      # Use SQL literals/identifiers, and pass the password by environment instead of logging or building SQL in Bash.
      ROLE_PASSWORD="$role_password" "${psql_cmd[@]}" --dbname=postgres --set=role_name="$role" <<'SQL'
\getenv role_password ROLE_PASSWORD
SELECT format(
    CASE WHEN EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = :'role_name')
        THEN 'ALTER ROLE %I WITH LOGIN PASSWORD %L'
        ELSE 'CREATE ROLE %I WITH LOGIN PASSWORD %L'
    END,
    :'role_name', :'role_password'
)
\gexec
SQL
      grant_role "$role"
    done
    ;;
esac
echo 'Todo database, schema, and application access are ready.'
