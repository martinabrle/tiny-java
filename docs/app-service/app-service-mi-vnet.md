# Private App Service with PostgreSQL Flexible Server

[The VNET template](../../scripts/templates/app-service-mi-vnet.bicep) provisions PostgreSQL 16 Flexible Server with Microsoft Entra authentication, App Service, and a small Ubuntu runner VM. Production reaches the database through a delegated App Service subnet, Private Link, and the linked `privatelink.postgres.database.azure.com` DNS zone. Production web and SCM endpoints are also private. The staging slot continues to use in-memory H2.

## Provision the infrastructure

1. Use a **private deployment repository** restricted to trusted maintainers. Do not register this runner against the public sample repository: it can administer this PostgreSQL server and publish to this App Service. Protect the release branch and restrict the `APP-SERVICE` environment to trusted branches.
2. Set up `APP-SERVICE` as described in the [GitHub Actions guide](app-service-github-actions.md), including the VNET-only runner settings. The workflow sends a one-hour registration token to the VM as a protected Azure Run Command parameter; the GitHub administration token stays in GitHub.
3. Run `cicd-app-service-infra` with **deploy** enabled and `VNET` selected. Leave **run_cleanup** unchecked. The workflow reports the runner name after GitHub shows it online. The VM has no public interface or inbound access. The NAT gateway provides outbound GitHub and package access and incurs charges along with the VM.

An existing Single Server is not upgraded in place. Use a new Flexible Server name for a migration, back up and restore or migrate the data separately, and plan the application cutover before pointing production at the new server.

## Deploy and test the application

Run `cicd-app-service` with **deploy** enabled. The hosted job builds the JAR; the deployment job requires the exact runner registered for the target App Service. On that VM it verifies private PostgreSQL DNS and TLS, then uses the VM's managed identity to run the [database bootstrap](../../scripts/bootstrap-app-service-db.sh). Repeating the release preserves the existing database and grants. An existing database role bound to a different Entra identity is reported as an error rather than rebound.

The same runner smoke-tests the H2 staging slot, publishes the JAR directly to private production rather than swapping the slots, and checks `/api/todos/` in production. The application uses its own managed identity and does not receive database administrator rights. A database restored from backup may require the existing table owner to delegate grants to the runner before the first release.
