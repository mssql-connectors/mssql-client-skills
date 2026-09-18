---
name: sql-connectivity-debug
description: Diagnose SQL Server or Azure SQL connectivity failures across drivers (ODBC, JDBC, Microsoft.Data.SqlClient, mssql-python, go-mssqldb, Node mssql) and languages. Use when the user reports a connection timeout, TLS/certificate error, login failure, "cannot connect", or "server not found" error, or asks to troubleshoot why an app can't reach SQL Server.
---

# SQL Server connectivity debugging

## When to use

Any "my app/tool can't connect to SQL Server" report: timeouts, TLS/certificate
errors, login failures, "server not found or not accessible", intermittent
disconnects. Not for writing new application code — hand off to the matching
`sql-app-*` skill once connectivity is confirmed working.

## Method

Work through `../_shared/troubleshooting-checklist.md` layer by layer: name
resolution/network → TCP/TLS handshake → authentication → server-side acceptance.
Don't jump to driver-specific trace logs before ruling out network/TLS with
`sqlcmd`/`Test-NetConnection` — most reported "driver bugs" are actually layer 1-2
issues that look identical from inside the app.

Use `scripts/probe-connection.ps1` to run the standard layered probe instead of typing
these commands by hand each time:

```powershell
.\scripts\probe-connection.ps1 -Server <host> -Port 1433
```

It reports DNS resolution, TCP reachability, and (if `sqlcmd` is available) a bare
`sqlcmd` connection attempt with and without encryption forced — which isolates
whether a failure is network-layer or TLS/auth-layer before any application code gets
involved.

## Tool reference

| Tool | Layer | Notes |
|---|---|---|
| `Resolve-DnsName` / `nslookup` | DNS | Confirm the hostname resolves to the expected IP |
| `Test-NetConnection -Port 1433` | TCP reachability | Fast refusal vs timeout tells you firewall vs "nothing listening" |
| `sqlcmd -S <server> -U <user> -P <pwd> -C` | TCP+TLS+auth, driver-agnostic | Cuts the application/driver out of the loop entirely |
| `sqlcmd ... -N -C` / `-N -C -y 0` | TLS specifically | Compare forced-encryption vs default behavior |
| ODBC trace (`odbcconf` / `Driver Manager` tracing) | ODBC driver internals | Only after network+auth ruled out |
| JDBC `logAppName`, driver logging config | JDBC driver internals | Only after network+auth ruled out |
| `Microsoft.Data.SqlClient` `EventSource`/diagnostics | .NET driver internals | Only after network+auth ruled out |
| Wireshark/tcpdump on port 1433 | Wire-level | Last resort when tool output disagrees with observed behavior |

## Common root causes, ranked by frequency

1. Firewall/NSG blocking the port (works from one network, not another).
2. `Encrypt`/`TrustServerCertificate` mismatch after a driver version upgrade changed
   the default (see `../_shared/connection-strings.md`).
3. Named instance without SQL Browser access and no pinned port.
4. AAD/Managed Identity token acquisition failing independently of the SQL driver.
5. Login exists at the server but has no database user mapping, or lacks `CONNECT SQL`.
6. Client-side connection pool exhaustion misreported as a connection failure.

## Reporting back

State which layer failed and the specific evidence (DNS resolved but TCP timed out;
TCP connected but TLS handshake failed; etc.), not just "connection failed". The fix
differs by layer, and restating the original symptom back to the user doesn't help
them.
