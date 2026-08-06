# Smoke the full Docker stack (requires Docker Desktop).
# Usage (from practica-stack):  powershell -File scripts/smoke-stack-docker.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$dockerBin = Join-Path $env:ProgramFiles 'Docker\Docker\resources\bin'
$dockerDesktop = Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'
$dockerCli = Join-Path $dockerBin 'docker.exe'

if (Test-Path $dockerBin) {
    if ($env:Path -notlike "*$dockerBin*") {
        $env:Path = "$dockerBin;" + $env:Path
    }
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue) -and -not (Test-Path $dockerCli)) {
    Write-Error @'
Docker CLI not found under "C:\Program Files\Docker\Docker\resources\bin".
Install Docker Desktop, then open a NEW terminal (or reboot) and re-run.
  winget install -e --id Docker.DockerDesktop
'@
}

function Test-DockerEngine {
    & docker info 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}

if (-not (Test-DockerEngine)) {
    if (-not (Get-Process -Name 'Docker Desktop' -ErrorAction SilentlyContinue) -and (Test-Path $dockerDesktop)) {
        Write-Host 'Starting Docker Desktop...' -ForegroundColor Yellow
        Start-Process -FilePath $dockerDesktop
    } else {
        Write-Host 'Waiting for Docker engine...' -ForegroundColor Yellow
    }

    $deadline = (Get-Date).AddMinutes(5)
    while ((Get-Date) -lt $deadline) {
        if (Test-DockerEngine) { break }
        Start-Sleep -Seconds 5
        Write-Host '  still waiting for docker info...' -ForegroundColor DarkGray
    }

    if (-not (Test-DockerEngine)) {
        Write-Error @'
Docker engine is not ready.
1) Open "Docker Desktop" from the Start menu
2) Wait until it says "Docker Desktop is running" / engine green
3) Re-run this script in a new PowerShell window
'@
    }
}

Write-Host ("Docker OK: {0}" -f (& docker version --format '{{.Server.Version}}')) -ForegroundColor Green

if (-not (Test-Path (Join-Path $root '.env'))) {
    Copy-Item (Join-Path $root '.env.example') (Join-Path $root '.env')
    Write-Host 'Created .env from .env.example' -ForegroundColor Yellow
}

foreach ($sib in @('ms-auth', 'practica', 'ms-frontend')) {
    $p = Join-Path (Split-Path -Parent $root) $sib
    if (-not (Test-Path $p)) {
        Write-Error "Missing sibling repo: $p"
    }
}

Write-Host '==> docker compose down --remove-orphans (avoid name conflicts)' -ForegroundColor Cyan
docker compose down --remove-orphans 2>$null

Write-Host '==> docker compose up --build -d' -ForegroundColor Cyan
docker compose up --build -d
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

function Wait-HttpOk([string]$Url, [int]$TimeoutSec = 180) {
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        try {
            $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
            if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 300) {
                Write-Host "OK $Url -> $($r.StatusCode)" -ForegroundColor Green
                return
            }
        } catch {
            Start-Sleep -Seconds 5
        }
    }
    Write-Error "Timeout waiting for $Url"
}

Write-Host '==> health checks' -ForegroundColor Cyan
Wait-HttpOk 'http://localhost:8081/actuator/health' 300
Wait-HttpOk 'http://localhost:8082/api/actuator/health' 300
Wait-HttpOk 'http://localhost:3000/health' 180

Write-Host '==> login smoke (admin / Admin123!)' -ForegroundColor Cyan
$body = '{"username":"admin","password":"Admin123!"}'
$login = Invoke-RestMethod -Method Post -Uri 'http://localhost:8081/api/auth/login' `
    -ContentType 'application/json' -Body $body
$token = $null
if ($login.data -and $login.data.sessionToken) { $token = $login.data.sessionToken }
elseif ($login.sessionToken) { $token = $login.sessionToken }
if (-not $token) {
    Write-Host ($login | ConvertTo-Json -Depth 6)
    Write-Error 'Login did not return sessionToken'
}
Write-Host "Login OK (token length=$($token.Length))" -ForegroundColor Green

Write-Host ''
Write-Host 'Stack smoke passed.' -ForegroundColor Green
Write-Host 'UI: http://localhost:3000  (admin / Admin123!)'
Write-Host 'Stop: docker compose down'
