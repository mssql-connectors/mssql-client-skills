---
name: sql-server-container
description: Start and manage a local SQL Server container for development using Docker, WSLc on Windows, macOS container tooling, or Podman. Use when the user asks to boot, run, stop, or prepare a local SQL Server instance in a container, choose a SQL Server image version, or make a container database available for client development.
---

# Local SQL Server container

## When to use

Use this skill to make a disposable or persistent local SQL Server instance
available for application development and integration tests. This skill is for
container lifecycle and readiness, not server administration or application
query code. Once the container is running but a client cannot connect, hand
off to `sql-connectivity-debug`.

## Select the runtime

Prefer WSLc on Windows and Docker on other supported hosts:

- Windows: WSL containers (`wslc.exe`), then Docker (`docker`), then Podman.
- macOS: the native container CLI (`container`), then Docker, then Podman.
- Linux: Docker, then Podman.

Check both the executable and that the runtime can answer a harmless version or
listing command before starting SQL Server. Do not silently install a runtime.
If none is available, tell the user which capability is missing and offer the
platform-specific setup:

- Windows WSLc: install/update WSL and enable the WSL container preview. WSLc
  requires WSL 2.9.3 or later; use `wsl --update --pre-release`, then verify
  with `wsl --version` and `wslc.exe image ls`.
- Docker: install Docker Desktop or Docker Engine, then retry `docker version`.
- macOS: install and start the native container runtime that provides
  `container`, then verify with `container system status` or its equivalent.
- Podman: install Podman and start its machine where required, then retry
  `podman info`.

## Choose the SQL Server image

Unless the user explicitly requests another release, you MUST use SQL Server
2025. Do not select SQL Server 2022 as an implicit compatibility fallback.
Use this image:

```text
mcr.microsoft.com/mssql/server:2025-latest
```

Allow the caller to override the complete image reference (for example,
`mcr.microsoft.com/mssql/server:2022-latest`) through `SQLSERVER_IMAGE`, but
only when the user explicitly asks for SQL Server 2022.
Do not invent or silently substitute a tag when the requested tag cannot be
pulled; report the pull error and ask whether to use another supported tag.

Set a strong local-development password through `MSSQL_SA_PASSWORD`; never
hardcode it in a command, file, or response. SQL Server containers require:

```text
ACCEPT_EULA=Y
MSSQL_SA_PASSWORD=<secret>
```

Use a named volume for data that should survive container replacement. Publish
the default SQL Server port explicitly:

```text
1433:1433
```

## Start with Docker or Podman

Use the same arguments with either `docker` or `podman`:

```bash
RUNTIME=docker
SQLSERVER_IMAGE="${SQLSERVER_IMAGE:-mcr.microsoft.com/mssql/server:2025-latest}"
SQLSERVER_CONTAINER="${SQLSERVER_CONTAINER:-sqlserver-dev}"

"$RUNTIME" run --name "$SQLSERVER_CONTAINER" \
  --hostname "$SQLSERVER_CONTAINER" \
  --detach \
  --publish 1433:1433 \
  --env ACCEPT_EULA=Y \
  --env MSSQL_SA_PASSWORD="$MSSQL_SA_PASSWORD" \
  --volume sqlserver-data:/var/opt/mssql \
  "$SQLSERVER_IMAGE"
```

If a container with that name already exists, inspect it first. Start it if it
is stopped; do not remove it or its volume without the user's approval.

## Start with WSLc on Windows

Use the WSLc CLI directly; it is not a Docker wrapper:

```powershell
$image = if ($env:SQLSERVER_IMAGE) {
  $env:SQLSERVER_IMAGE
} else {
  "mcr.microsoft.com/mssql/server:2025-latest"
}

wslc.exe run --name sqlserver-dev --detach `
  --publish 1433:1433 `
  --env ACCEPT_EULA=Y `
  --env MSSQL_SA_PASSWORD="$env:MSSQL_SA_PASSWORD" `
  $image
```

Use `wslc.exe image ls`, `wslc.exe container ps`, and
`wslc.exe container stop sqlserver-dev` for inspection and lifecycle control.
Use an explicit WSLc volume or mount supported by the installed preview when
persistence is required; verify its syntax with `wslc.exe run --help` rather
than assuming Docker volume flags are identical.

## Start with macOS container tooling

Use the native `container` CLI when it is installed and running. Keep the same
image, environment, port, and volume intent, but check the installed CLI's
`container run --help` for the exact volume and detach options because this
runtime is not Docker-compatible in every release.

## Wait for readiness

Starting the process is not proof that SQL Server accepts connections. Poll
until the container is running and port 1433 is reachable, then run a simple
authentication probe with the supplied credentials. Use a bounded timeout and
report logs when readiness fails:

```bash
"$RUNTIME" ps --filter "name=$SQLSERVER_CONTAINER"
"$RUNTIME" logs --tail 100 "$SQLSERVER_CONTAINER"
```

Do not claim success while SQL Server is still initializing. If the port is
reachable but authentication or TLS fails, hand off to
`sql-connectivity-debug` with the runtime, image tag, published port, and
observed error.

## Lifecycle

Preserve the named volume by default:

```bash
"$RUNTIME" stop "$SQLSERVER_CONTAINER"
"$RUNTIME" start "$SQLSERVER_CONTAINER"
"$RUNTIME" rm "$SQLSERVER_CONTAINER"
```

Only remove `sqlserver-data` after explicitly confirming that all local data can
be discarded. For WSLc and macOS container tooling, use their corresponding
`container`/volume commands and verify help output before destructive actions.
