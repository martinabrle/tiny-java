\set ON_ERROR_STOP on

BEGIN;

SELECT format(
    'SELECT pg_catalog.pgaadauth_create_principal_with_oid(%L, %L, %L, false, false)',
    :'role_name', :'principal_id', 'service'
)
WHERE NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = :'role_name')
\gexec

SELECT EXISTS (
    SELECT FROM pg_catalog.pgaadauth_list_principals(false)
        AS principal(role_name, principal_type, object_id, tenant_id, is_mfa, is_admin)
    WHERE principal.role_name = :'role_name'
      AND principal.principal_type = 'service'
      AND lower(principal.object_id) = lower(:'principal_id')
      AND principal.is_admin = 0
) AS role_matches
\gset

\if :role_matches
\else
DO $$
BEGIN
    RAISE EXCEPTION 'Existing database role is not the expected non-admin Microsoft Entra principal';
END;
$$;
\endif

COMMIT;
