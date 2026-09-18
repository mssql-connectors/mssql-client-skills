---
name: sql-app-jdbc
description: Scaffold and build Java applications that connect to SQL Server or Azure SQL using the Microsoft JDBC Driver (mssql-jdbc), plain JDBC, or a framework like Spring Data JPA/Hibernate. Use when the user asks to write or fix Java code that reads or writes SQL Server data, configures a DataSource, or runs queries against SQL Server.
---

# Java (JDBC) SQL Server app development

## When to use

Any request to write or modify Java code that talks to SQL Server via the Microsoft
JDBC Driver, whether plain JDBC, a connection pool (HikariCP), or Spring Data
JPA/Hibernate. Not for connectivity *troubleshooting* — use `sql-connectivity-debug`.

## Dependency

Use the Microsoft JDBC Driver for SQL Server (`com.microsoft.sqlserver:mssql-jdbc`),
not the older jTDS driver, unless the project has an existing jTDS dependency that
can't yet be migrated.

## Connection setup

```java
String url = "jdbc:sqlserver://<host>:1433;databaseName=<db>;encrypt=true;trustServerCertificate=false";
try (Connection conn = DriverManager.getConnection(url, "<user>", "<pwd>")) {
    try (PreparedStatement ps = conn.prepareStatement("SELECT TOP 10 * FROM dbo.SomeTable")) {
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                // process row
            }
        }
    }
}
```

For Azure AD / Managed Identity, use the `authentication=ActiveDirectoryDefault` (or
`ActiveDirectoryManagedIdentity`) connection property instead of manually acquiring a
token, unless the app already owns an MSAL/Azure Identity token flow.

## Patterns to follow

- Always use try-with-resources for `Connection`/`Statement`/`ResultSet` — don't rely
  on finalizers.
- Always use `PreparedStatement` with bound parameters — never string-concatenate
  values into SQL.
- Use a pooled `DataSource` (HikariCP is the common default, including Spring Boot's
  default) rather than opening a raw `DriverManager` connection per request in
  anything beyond a script.
- For bulk loads, use `SQLServerBulkCopy` rather than row-by-row inserts.
- With Spring Data JPA/Hibernate, configure the dialect and connection properties
  (`encrypt`, `trustServerCertificate`) in `application.properties`/`application.yml`,
  not scattered across code.

## Verifying

Compile and, if a reachable test database is available, run a smoke query or the
relevant test/integration-test module. If the connection itself fails, hand off to
`sql-connectivity-debug` rather than iterating on connection properties blind.
