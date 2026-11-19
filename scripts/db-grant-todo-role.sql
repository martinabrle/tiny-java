\set ON_ERROR_STOP on

BEGIN;
GRANT CONNECT ON DATABASE :"db_name" TO :"role_name";
GRANT USAGE ON SCHEMA public TO :"role_name";
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.todo TO :"role_name";

SELECT pg_catalog.has_database_privilege(:'role_name', :'db_name', 'CONNECT')
   AND pg_catalog.has_schema_privilege(:'role_name', 'public', 'USAGE')
   AND pg_catalog.has_table_privilege(:'role_name', 'public.todo', 'SELECT')
   AND pg_catalog.has_table_privilege(:'role_name', 'public.todo', 'INSERT')
   AND pg_catalog.has_table_privilege(:'role_name', 'public.todo', 'UPDATE')
   AND pg_catalog.has_table_privilege(:'role_name', 'public.todo', 'DELETE') AS access_ready
\gset

\if :access_ready
\else
DO $$
BEGIN
    RAISE EXCEPTION 'Todo role is missing one or more required privileges';
END;
$$;
\endif
COMMIT;
