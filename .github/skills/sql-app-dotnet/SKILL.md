---
name: sql-app-dotnet
description: Scaffold and build .NET applications (console, ASP.NET Core, worker services) that connect to SQL Server or Azure SQL using Microsoft.Data.SqlClient, Dapper, or Entity Framework Core. Use when the user asks to write, generate, or fix .NET/C# code that reads or writes SQL Server data, sets up a connection, or configures EF Core migrations against SQL Server.
---

# .NET SQL Server app development

## When to use

Any request to write or modify .NET/C# code that talks to SQL Server: raw ADO.NET,
Dapper, or EF Core. Not for connectivity *troubleshooting* — that's
`sql-connectivity-debug`; use its troubleshooting-checklist if a generated app can't
connect.

## Picking a data access approach

| Approach | Use when |
|---|---|
| `Microsoft.Data.SqlClient` (raw ADO.NET) | Full control, high-performance batch/bulk paths, existing raw-SQL codebase |
| Dapper | Want raw SQL but with object mapping, no change-tracking overhead |
| EF Core (`Microsoft.EntityFrameworkCore.SqlServer`) | Need migrations, LINQ, change tracking, rapid CRUD scaffolding |

Default to `Microsoft.Data.SqlClient` (not the legacy `System.Data.SqlClient`, which is
in maintenance mode) for anything doing its own SQL.

## Connection setup

Use `SqlConnectionStringBuilder` instead of hand-built strings so parameters are
validated and correctly escaped:

```csharp
var csb = new SqlConnectionStringBuilder
{
    DataSource = "tcp:<host>,1433",
    InitialCatalog = "<db>",
    Encrypt = true,
    TrustServerCertificate = false,
    Authentication = SqlAuthenticationMethod.ActiveDirectoryDefault, // or SqlPassword
};
await using var conn = new SqlConnection(csb.ConnectionString);
await conn.OpenAsync();
```

For Managed Identity/AAD scenarios prefer `SqlAuthenticationMethod.ActiveDirectoryDefault`
or `ActiveDirectoryManagedIdentity` over manually acquiring and injecting an access
token, unless the app already owns token acquisition (e.g. via `Azure.Identity`).

See `../_shared/connection-strings.md` for auth-mode and encryption details common to
all languages.

## Patterns to follow

- Always `await using`/`using` connections and commands — don't rely on GC.
- Use parameterized commands (`SqlParameter`) — never string-interpolate values into SQL.
- For bulk loads, prefer `SqlBulkCopy` over row-by-row inserts.
- For retryable transient faults (throttling, failover), wrap execution with a retry
  policy (e.g. Polly) rather than a bespoke retry loop, and only retry on transient
  error numbers, not all `SqlException`s.
- With EF Core: put the connection string and `Encrypt`/`TrustServerCertificate`
  settings in configuration, not hardcoded in `OnConfiguring`; generate migrations with
  `dotnet ef migrations add` rather than hand-editing the model snapshot.

## Verifying

After scaffolding, build the project (`dotnet build`) and, if a reachable test database
is available, run a smoke query. If the connection fails, hand off to
`sql-connectivity-debug` rather than guessing at connection-string tweaks.
