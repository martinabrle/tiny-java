# Copilot instructions for tiny-java

- Do not use `msx-mcp` (including `hok-dashboard`) or Partner IQ in this repository. Use repository files and GitHub tooling for repository work.

## Application

- The Maven module is `todo/`. Keep changes compatible with Java 11 and Spring Boot 2.7 unless the task explicitly changes the baseline. Use the module's Maven wrapper.
- Follow the existing `app.demo.todo` layers: REST and Thymeleaf controllers delegate to the service, which uses the JPA repository. Keep API DTOs separate from persistence entities. For shared behavior changes, check both the REST and web paths.
- Use the `local` profile for routine development and tests. It uses in-memory H2; `test` is a PostgreSQL deployment profile, not the profile for local Maven tests.
- For persistence changes, check both H2 and PostgreSQL compatibility. The local profile updates the schema via Hibernate, while deployed PostgreSQL profiles validate it. Check [the PostgreSQL schema script](../scripts/db.sql) when changing entity mappings.

## Build and test locally

Run from the repository root in PowerShell with JDK 11:

```powershell
Set-Location .\todo
$env:SPRING_PROFILES_ACTIVE = 'local'
$env:PORT = '8080'
.\mvnw.cmd test
```

In Bash, run `cd todo` from the repository root, then `SPRING_PROFILES_ACTIVE=local PORT=8080 ./mvnw test`. With the same settings, use `spring-boot:run` instead of `test` to start the app. Add or update focused JUnit tests under `todo/src/test/java` for behavior changes. H2 tests do not verify PostgreSQL or Azure authentication behavior.

## Azure deployment

- Check [deployment docs](../docs/), [Bicep templates](../scripts/templates/), and [GitHub Actions workflows](./workflows/) together when changing a deployment contract such as a port, health endpoint, environment variable, or identity setting.
- Preserve the distinction between password-based PostgreSQL and Entra-authenticated `*-mi` profiles. Keep secrets and tokens out of code, examples, and logs.
- Prefer local validation. Do not provision, deploy, or delete Azure resources unless the user explicitly requests it.
