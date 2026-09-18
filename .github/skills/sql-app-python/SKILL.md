---
name: sql-app-python
description: Scaffold and build Python applications that connect to SQL Server or Azure SQL using the mssql-python driver, pyodbc, or SQLAlchemy. Use when the user asks to write or fix Python code that reads or writes SQL Server data, opens a connection, or runs queries against SQL Server.
---

# Python SQL Server app development

## When to use

Any request to write or modify Python code that talks to SQL Server. Not for
connectivity *troubleshooting* — use `sql-connectivity-debug` for that.

## Picking a driver

| Driver | Use when |
|---|---|
| `mssql-python` (Microsoft's pure driver, no ODBC install needed) | New projects; simplest setup, no system ODBC driver/DSN required |
| `pyodbc` | Need to reuse an existing system ODBC driver/DSN, or a library/framework expects DB-API over ODBC |
| `SQLAlchemy` (+ `mssql-python` or `pyodbc` dialect) | ORM, need engine/session abstractions, connection pooling config |

Default to `mssql-python` for new scripts/services since it avoids the separate ODBC
driver install step; reach for `pyodbc` when the environment already standardizes on
system ODBC (e.g. shared DSNs, existing `odbcinst.ini` config).

## Connection setup

```python
import mssql_python

conn = mssql_python.connect(
    server="tcp:<host>,1433",
    database="<db>",
    uid="<user>",
    pwd="<pwd>",       # or use Authentication=ActiveDirectoryDefault for AAD/MI
    encrypt="yes",
    trust_server_certificate="no",
)
cur = conn.cursor()
cur.execute("SELECT TOP 10 * FROM dbo.SomeTable")
for row in cur.fetchall():
    print(row)
```

With `pyodbc`, the same parameters go into an ODBC connection string (see
`../_shared/connection-strings.md`).

## Patterns to follow

- Always parameterize queries (`cur.execute(sql, params)`) — never f-string values into
  SQL.
- Use context managers (`with conn:`, `with conn.cursor() as cur:`) so connections close
  on error paths.
- For bulk loads, use the driver's bulk-copy support (or `executemany` with batching)
  rather than a Python loop of single-row inserts.
- With SQLAlchemy, configure pool size/timeout explicitly for services under load;
  don't rely on defaults for anything beyond a script.
- Read connection/auth errors from the driver's exception message before assuming
  it's a code bug — mssql-python and pyodbc both surface the server's error text.

## Verifying

Run the script/tests against a reachable test database. If the connection itself
fails (not a query error), hand off to `sql-connectivity-debug` instead of iterating on
the connection string blind.
