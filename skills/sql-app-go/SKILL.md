---
name: sql-app-go
description: Scaffold and build Go applications that connect to SQL Server or Azure SQL using the go-mssqldb driver via database/sql. Use when the user asks to write or fix Go code that reads or writes SQL Server data, configures a *sql.DB connection pool, or runs queries against SQL Server.
---

# Go SQL Server app development

## When to use

Any request to write or modify Go code that talks to SQL Server via
`microsoft/go-mssqldb` and the standard `database/sql` package. Not for connectivity
*troubleshooting* — use `sql-connectivity-debug`.

## Connection setup

```go
import (
    "database/sql"
    _ "github.com/microsoft/go-mssqldb"
)

dsn := "sqlserver://<user>:<pwd>@<host>:1433?database=<db>&encrypt=true&trustservercertificate=false"
db, err := sql.Open("sqlserver", dsn)
if err != nil {
    // handle
}
defer db.Close()

ctx := context.Background()
if err := db.PingContext(ctx); err != nil {
    // handle: connection/auth/network failure
}
```

For Azure AD / Managed Identity, use the driver's `fedauth` connection parameter
(e.g. `fedauth=ActiveDirectoryDefault` or `ActiveDirectoryManagedIdentity`) rather than
manually acquiring a token, unless the app already owns an `azidentity` token flow.

## Patterns to follow

- `sql.Open` does not open a connection — it only validates the DSN. Always
  `PingContext` (or run a first query) to actually verify connectivity.
- `*sql.DB` is a pool; construct it once per process/service, not per request.
- Configure `SetMaxOpenConns`, `SetMaxIdleConns`, `SetConnMaxLifetime` explicitly for
  services under load — the defaults (unlimited open, no lifetime) can exhaust server
  connections or hold stale connections through a failover.
- Always use parameterized queries (`db.QueryContext(ctx, sql, args...)`) — never
  string-format values into SQL.
- Always pass a `context.Context` with an appropriate deadline/cancellation rather than
  the non-context variants.

## Verifying

Build (`go build ./...`) and, if a reachable test database is available, run a smoke
query or the relevant test package. If `PingContext`/queries fail at the connection
step, hand off to `sql-connectivity-debug` rather than iterating on the DSN blind.
