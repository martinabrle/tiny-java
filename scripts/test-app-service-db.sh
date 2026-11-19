#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
pg_bin=/usr/lib/postgresql/16/bin
test_root=$(mktemp -d)
trap '"$pg_bin/pg_ctl" -D "$test_root/data" -m fast stop >/dev/null 2>&1 || true' EXIT

export DEPLOYMENT_MODE=CLASSIC RESOURCE_GROUP=fixture APP_NAME=tiny-java DB_SERVER=fixture DB_NAME=tododb
export VAULT_NAME=fixture DB_ADMIN_PASSWORD=test-admin-password
export PGHOSTADDR=127.0.0.1 PGPORT=15432 PGSSLMODE=verify-full PGSSLROOTCERT="$test_root/server.crt"
export PGUSER=test_admin PGPASSWORD="$DB_ADMIN_PASSWORD" PGHOST="$DB_SERVER.postgres.database.azure.com"

printf '%s\n' "$PGPASSWORD" > "$test_root/password"
"$pg_bin/initdb" -D "$test_root/data" --username="$PGUSER" --auth=scram-sha-256 \
  --pwfile="$test_root/password" > /dev/null
openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj "/CN=$PGHOST" \
  -addext "subjectAltName=DNS:$PGHOST" \
  -keyout "$test_root/server.key" -out "$PGSSLROOTCERT" 2>/dev/null
chmod 600 "$test_root/server.key"
"$pg_bin/pg_ctl" -D "$test_root/data" -l "$test_root/postgres.log" -w start \
  -o "-h 127.0.0.1 -p $PGPORT -k $test_root -c ssl=on -c ssl_cert_file=$PGSSLROOTCERT -c ssl_key_file=$test_root/server.key" > /dev/null

# Substitute only Azure lookups; the database connections and SQL below are real.
az() {
  case "$1 $2 $3" in
    'postgres flexible-server show') echo test_admin ;;
    'keyvault secret show')
      if [[ " $* " == *' --name SPRING-DATASOURCE-PASSWORD-STAGING '* ]]; then
        echo 'test staging password'
      else
        echo "test 'production' password"
      fi
      ;;
    *) echo "Unexpected Azure command during the test: $1 $2 $3" >&2; return 1 ;;
  esac
}
export -f az

psql_test=(psql -X -w --set=ON_ERROR_STOP=1)
[[ "$("${psql_test[@]}" --dbname=postgres -Atc "SELECT count(*) FROM pg_database WHERE datname = 'tododb'")" == 0 ]]
bash ./bootstrap-app-service-db.sh
PGUSER=tiny_java PGPASSWORD="test 'production' password" \
  "${psql_test[@]}" --dbname="$DB_NAME" \
  --command="INSERT INTO public.todo (id, todo_text) VALUES (gen_random_uuid(), 'kept on redeploy')"
bash ./bootstrap-app-service-db.sh
count=$(PGUSER=tiny_java_staging PGPASSWORD='test staging password' \
  "${psql_test[@]}" --dbname="$DB_NAME" -Atc "SELECT count(*) FROM public.todo WHERE todo_text = 'kept on redeploy'")
[[ "$count" == 1 ]]
[[ "$("${psql_test[@]}" --dbname=postgres -Atc "SELECT count(*) FROM pg_roles WHERE rolname IN ('tiny_java', 'tiny_java_staging') AND rolcanlogin AND NOT (rolsuper OR rolcreaterole OR rolcreatedb)")" == 2 ]]
echo 'PostgreSQL bootstrap passed: fresh database, both application roles, and data preserved on redeploy.'
