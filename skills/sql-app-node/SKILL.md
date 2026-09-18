---
name: sql-app-node
description: Scaffold and build Node.js/TypeScript applications that connect to SQL Server or Azure SQL using the mssql (Tedious) package or Knex/Sequelize. Use when the user asks to write or fix Node.js or TypeScript code that reads or writes SQL Server data, configures a connection pool, or runs queries against SQL Server.
---

# Node.js SQL Server app development

## When to use

Any request to write or modify Node.js/TypeScript code that talks to SQL Server. Not
for connectivity *troubleshooting* — use `sql-connectivity-debug`.

## Picking a package

| Package | Use when |
|---|---|
| `mssql` (wraps Tedious) | Default choice; connection pooling, prepared statements, streaming built in |
| `tedious` directly | Need low-level control the `mssql` wrapper doesn't expose |
| Knex / Sequelize / Prisma | Need a query builder or ORM, migrations, multi-database portability |

Default to `mssql` for anything doing its own SQL; reach for an ORM only when the
project already wants ORM-level abstractions (migrations, model definitions).

## Connection setup

```ts
import sql from "mssql";

const pool = await sql.connect({
  server: "<host>",
  port: 1433,
  database: "<db>",
  user: "<user>",
  password: "<pwd>",       // or use options.authentication for AAD/MI
  options: {
    encrypt: true,
    trustServerCertificate: false,
  },
});

const result = await pool.request().query("SELECT TOP 10 * FROM dbo.SomeTable");
```

For Azure AD / Managed Identity, set `authentication.type` (e.g.
`azure-active-directory-msi-app-service`, `azure-active-directory-default`) rather than
manually acquiring a token, unless the app already owns token acquisition.

## Patterns to follow

- Reuse a single connection pool for the app's lifetime — don't call `sql.connect()`
  per request.
- Use parameterized requests (`request.input(...)` / tagged template queries) — never
  string-interpolate values into SQL.
- Handle pool-level `error` events; an unhandled pool error can crash the process.
- For bulk loads, use `sql.Table`/bulk insert support rather than looping individual
  inserts.
- Close the pool on graceful shutdown (`pool.close()`).

## Verifying

Run the app/tests against a reachable test database. If the connection itself fails,
hand off to `sql-connectivity-debug` rather than iterating on connection options blind.
