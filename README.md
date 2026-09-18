# mssql-client-skills

GitHub Copilot skills for SQL Server **client** development: building applications that
connect to SQL Server or Azure SQL in various languages, and diagnosing client-side
connectivity failures. Client-side only — this repo is not about server administration,
tuning, or T-SQL authoring.

## Layout

```
.github/skills/
  sql-app-dotnet/           .NET (Microsoft.Data.SqlClient / Dapper / EF Core)
  sql-app-python/           Python (mssql-python / pyodbc / SQLAlchemy)
  sql-app-jdbc/             Java (mssql-jdbc, plain JDBC or Spring Data JPA)
  sql-app-node/             Node.js/TypeScript (mssql / Tedious / Knex / Sequelize)
  sql-app-go/               Go (go-mssqldb via database/sql)
  sql-connectivity-debug/   Diagnose connection failures across all of the above
    scripts/probe-connection.ps1   Layered DNS -> TCP -> sqlcmd connectivity probe
  _shared/                  Reference docs linked from every skill above
    connection-strings.md          Auth modes, encryption, per-driver connection strings
    troubleshooting-checklist.md   Layered funnel used by sql-connectivity-debug
```

These are **project-scoped Copilot CLI skills**: they load automatically for anyone
using Copilot CLI in this repo — no install step. Each `SKILL.md` has YAML frontmatter
(`name`, `description`) the agent uses to decide relevance, followed by instructions.

## Adding a new skill

1. Create `.github/skills/<kebab-case-name>/SKILL.md`.
2. Write a `description` that states concrete trigger conditions (what request should
   load this skill), not just a topic label.
3. Link to `_shared/` docs instead of duplicating auth/encryption/troubleshooting
   content across skills.
4. Keep each skill narrow — one skill per language/tool, not one skill that tries to
   cover everything.

## Packaging as an installable plugin

Once these stabilize, they can be bundled into a distributable plugin (manifest +
`skills/` + optional `commands/`/MCP server) for use outside this repo, similar to
community plugins like `ponytail`. Not needed while iterating locally.
