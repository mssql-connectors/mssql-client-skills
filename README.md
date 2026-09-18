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
  sql-server-container/     Boot a local SQL Server container (Docker / WSLc / Podman)
  sql-connectivity-debug/   Diagnose connection failures across all of the above
    scripts/probe-connection.ps1   Layered DNS -> TCP -> sqlcmd connectivity probe
  _shared/                  Reference docs linked from every skill above
    connection-strings.md          Auth modes, encryption, per-driver connection strings
    troubleshooting-checklist.md   Layered funnel used by sql-connectivity-debug
plugin.json                 Installable plugin manifest
.github/plugin/marketplace.json  Marketplace catalog
```

These are **project-scoped Copilot CLI skills**: they load automatically for anyone
using Copilot CLI in this repo — no install step. Each `SKILL.md` has YAML frontmatter
(`name`, `description`) the agent uses to decide relevance.

## Adding a new skill

1. Create `.github/skills/<kebab-case-name>/SKILL.md`.
2. Write a `description` that states concrete trigger conditions (what request should
   load this skill), not just a topic label.
3. Link to `_shared/` docs instead of duplicating auth/encryption/troubleshooting
   content across skills.
4. Keep each skill narrow — one skill per language/tool, not one skill that tries to
   cover everything.

## Installing as a Copilot plugin

This repository is also a self-contained Copilot plugin marketplace. The marketplace
catalog lives at `.github/plugin/marketplace.json`, and the plugin manifest is
`plugin.json` at the repository root. The manifest references the existing skills in
`.github/skills/` without duplicating them.

From Copilot CLI, register the marketplace and install the plugin:

```bash
copilot plugin marketplace add mssql-connectors/mssql-client-skills
copilot plugin install mssql-client-skills@mssql-client-skills
```

To test changes locally, run Copilot CLI from the repository root. The project-scoped
skills under `.github/skills/` load automatically. To test the packaged form, install
the marketplace from the branch or commit containing your changes, then start a new
Copilot session and use prompts that match each skill description.
