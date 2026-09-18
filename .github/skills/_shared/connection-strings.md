# SQL Server connection reference

Shared by every `sql-app-*` skill and `sql-connectivity-debug`. Don't duplicate this
content inside a skill — link here and add only what's driver-specific there.

## Authentication modes

| Mode | When to use | Notes |
|---|---|---|
| SQL auth (`uid`/`pwd`) | Legacy, containers, local dev | Never hardcode credentials; use env vars / secret store |
| Windows/Integrated auth | Domain-joined Windows clients | `Trusted_Connection=yes` / `IntegratedSecurity=true` |
| Azure AD / Entra ID (password, MFA, MSI, service principal) | Azure SQL, Managed Instance | Driver-specific token acquisition; see each driver's page |
| Managed Identity | Apps running in Azure (App Service, VM, AKS) | No secret to rotate; requires driver support for `ActiveDirectoryManagedIdentity` |

## Encryption

- Default changed across driver versions: newer client drivers (ODBC 18+, JDBC 10+,
  Microsoft.Data.SqlClient 5+) default `Encrypt=yes` (mandatory, cert-validated) rather
  than the old opt-in behavior.
- `TrustServerCertificate=yes` disables certificate validation — dev/test only, never
  production. Prefer trusting the real CA or using `HostNameInCertificate`.
- Common failure: app pinned to an old default (`Encrypt=no`) now failing to connect to
  a server that requires TLS, or the reverse — client requires strict cert validation
  against a self-signed dev server cert.

## Minimal connection string / DSN-less patterns

- **ODBC**: `Driver={ODBC Driver 18 for SQL Server};Server=tcp:<host>,1433;Database=<db>;Uid=<user>;Pwd=<pwd>;Encrypt=yes;`
- **JDBC**: `jdbc:sqlserver://<host>:1433;databaseName=<db>;encrypt=true;trustServerCertificate=false;`
- **Microsoft.Data.SqlClient**: `Server=tcp:<host>,1433;Initial Catalog=<db>;Encrypt=True;TrustServerCertificate=False;`
- **Node (tedious/mssql)**: config object with `server`, `options.encrypt`, `authentication.type`.
- **Go (go-mssqldb)**: `sqlserver://<user>:<pwd>@<host>:1433?database=<db>&encrypt=true`
- **Python (mssql-python/pyodbc)**: same ODBC-style connection string, or driver-native
  kwargs where the driver supports them.

## Ports and networking

- Default instance: TCP 1433. Named instances: dynamic port, resolved via SQL Browser
  (UDP 1434) unless the port is pinned in the connection string.
- Azure SQL / Managed Instance: 1433 only (no SQL Browser); check NSG/firewall rules and
  server-level firewall (client IP allow-list).
