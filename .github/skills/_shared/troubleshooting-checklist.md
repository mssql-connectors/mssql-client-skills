# Connectivity troubleshooting funnel

Shared by `sql-connectivity-debug` and referenced by the `sql-app-*` skills when a
generated app fails to connect. Work top to bottom — each layer's failure symptoms
look similar to the next, so don't skip ahead.

## 1. Name resolution and network reachability

- Can the host resolve? `Resolve-DnsName <host>` / `nslookup <host>`
- Can you reach the port? `Test-NetConnection <host> -Port 1433`
- Named instance without a pinned port: check SQL Browser (UDP 1434) is reachable, or
  pin the port and skip browser resolution entirely.
- Symptom at this layer: connection timeout (not a fast refusal). Usually firewall,
  NSG, or VPN/peering, not the SQL Server instance itself.

## 2. TCP/TLS handshake

- Fast connection *refusal* (not timeout) usually means the port is reachable but
  nothing is listening, or wrong port.
- TLS/cert errors: verify server cert CN/SAN matches the hostname used in the
  connection string, check `TrustServerCertificate` vs `Encrypt`, and check the client
  OS trust store has the issuing CA (common on Linux clients hitting an internal CA).
- Client and server encryption requirements can mismatch (client forces encryption,
  server doesn't support it, or vice versa) — read the driver's negotiated-encryption
  error text carefully, it usually says which side refused.

## 3. Authentication

- SQL auth: verify SQL auth is enabled at the server (mixed mode), account not locked
  out/expired, correct case-sensitive collation if applicable.
- AAD/Entra: check token acquisition succeeded independently of the SQL driver (e.g.
  `az account get-access-token --resource https://database.windows.net/`) before
  blaming the driver.
- Managed Identity: confirm the identity is assigned and has an AAD login created on
  the target database (`CREATE USER ... FROM EXTERNAL PROVIDER`).

## 4. Server-side acceptance

- Server firewall rules (Azure SQL: IP allow-list, VNet rules).
- Max connections / resource governor limits.
- Login exists but lacks `CONNECT SQL` permission, or database-level user mapping is
  missing even though the server login exists.

## Tools to reach for, in order

1. `Test-NetConnection` / `tcping` / `nc -zv` — layer 1.
2. `sqlcmd -S <server> -U <user> -P <pwd> -C` (or `-N`/`-C` combinations to isolate
   encryption) — cuts out the app/driver entirely.
3. Driver-specific connection/trace logging (ODBC trace, JDBC `logAppName`/log config,
   `Microsoft.Data.SqlClient` event source, ADO diagnostics) — only after 1 and 2 rule
   out network and generic auth.
4. Packet capture (Wireshark/tcpdump on 1433) as the last resort when the above
   disagree with what's actually happening on the wire.

Report which layer failed, not just "connection failed" — the fix is different at
each layer and jumping straight to driver logs before confirming the network layer
wastes the most time.
