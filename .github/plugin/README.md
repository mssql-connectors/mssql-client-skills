# SQL Server Client Skills Plugin

GitHub Copilot skills for building applications that connect to SQL Server or Azure
SQL, and for diagnosing client-side connectivity failures.

## Installation

Register this repository as a Copilot plugin marketplace:

```bash
copilot plugin marketplace add mssql-connectors/mssql-client-skills
copilot plugin install mssql-client-skills@mssql-client-skills
```

The plugin includes skills for .NET, Python, Java/JDBC, Node.js/TypeScript, Go, and
cross-driver connectivity troubleshooting.

## Requirements

The skills provide guidance and may generate or validate application code. The
runtime, language SDKs, database drivers, and SQL Server credentials required by a
generated application are not bundled with this plugin.
