<#
.SYNOPSIS
    Layered probe for SQL Server connectivity issues: DNS -> TCP -> sqlcmd (encrypted
    and unencrypted) -- so a failure can be attributed to a specific layer instead of
    a generic "connection failed".

.PARAMETER Server
    Hostname or IP of the SQL Server / Azure SQL endpoint (no "tcp:" prefix, no port).

.PARAMETER Port
    TCP port to probe. Defaults to 1433.

.PARAMETER Database
    Optional database name for the sqlcmd probe. Defaults to "master".

.PARAMETER User
    Optional SQL auth username for the sqlcmd probe. If omitted, sqlcmd is invoked with
    -E (trusted/integrated auth) instead.

.PARAMETER Password
    Optional SQL auth password. Required if -User is supplied.

.EXAMPLE
    .\probe-connection.ps1 -Server myserver.database.windows.net -Port 1433
#>
param(
    [Parameter(Mandatory = $true)][string]$Server,
    [int]$Port = 1433,
    [string]$Database = "master",
    [string]$User,
    [string]$Password
)

function Write-Section($title) {
    Write-Host ""
    Write-Host "== $title ==" -ForegroundColor Cyan
}

Write-Section "1. DNS resolution"
try {
    $dns = Resolve-DnsName -Name $Server -ErrorAction Stop
    $dns | Format-Table Name, IPAddress -AutoSize
} catch {
    Write-Host "DNS resolution FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stop here -- fix name resolution before probing further layers." -ForegroundColor Yellow
    exit 1
}

Write-Section "2. TCP reachability ($Server`:$Port)"
$tcp = Test-NetConnection -ComputerName $Server -Port $Port
$tcp | Format-List ComputerName, RemotePort, TcpTestSucceeded, PingSucceeded
if (-not $tcp.TcpTestSucceeded) {
    Write-Host "TCP connect FAILED. Likely firewall/NSG, wrong port, or nothing listening." -ForegroundColor Red
    Write-Host "Stop here -- TLS/auth probes below cannot succeed without TCP reachability." -ForegroundColor Yellow
    exit 1
}

$sqlcmd = Get-Command sqlcmd -ErrorAction SilentlyContinue
if (-not $sqlcmd) {
    Write-Host ""
    Write-Host "sqlcmd not found on PATH -- skipping TLS/auth probe. Install the" -ForegroundColor Yellow
    Write-Host "'sqlcmd' utility (part of the ODBC driver / mssql-tools package) to" -ForegroundColor Yellow
    Write-Host "get a driver-agnostic TLS+auth check." -ForegroundColor Yellow
    exit 0
}

function Invoke-SqlcmdProbe([string]$label, [string[]]$extraArgs) {
    Write-Section $label
    $authArgs = if ($User) { @("-U", $User, "-P", $Password) } else { @("-E") }
    $args = @("-S", "$Server,$Port", "-d", $Database) + $authArgs + $extraArgs + @("-Q", "SELECT @@VERSION;", "-l", "10")
    & sqlcmd @args
    if ($LASTEXITCODE -ne 0) {
        Write-Host "sqlcmd exited with code $LASTEXITCODE" -ForegroundColor Red
    }
}

Invoke-SqlcmdProbe "3. sqlcmd probe -- default encryption (-C trusts server cert)" @("-C")
Invoke-SqlcmdProbe "4. sqlcmd probe -- encryption forced, cert validated (no -C)" @()

Write-Host ""
Write-Host "Interpretation:" -ForegroundColor Cyan
Write-Host " - Step 3 succeeds, step 4 fails => certificate validation problem" -ForegroundColor Gray
Write-Host "   (self-signed/dev cert, hostname mismatch, or missing CA trust)." -ForegroundColor Gray
Write-Host " - Both succeed => network+TLS+auth are fine; look at the app/driver" -ForegroundColor Gray
Write-Host "   configuration instead (connection string, pool settings, retry logic)." -ForegroundColor Gray
Write-Host " - Both fail with a login error => credentials/permissions, not network." -ForegroundColor Gray
Write-Host " - Both fail with a network/timeout error despite step 2 passing => check" -ForegroundColor Gray
Write-Host "   named-instance/SQL Browser resolution or a server-side connection limit." -ForegroundColor Gray
