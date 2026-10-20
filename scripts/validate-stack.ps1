# Local twin of .github/workflows/validate.yml.
# Checks the compose contract without building images: the file parses, the four
# services are declared, the .env template can drive the stack, and the sibling
# clones the build contexts point at are present (that part cannot run in CI).
# Usage: powershell -File scripts\validate-stack.ps1

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)

$failures = @()
function Fail([string]$msg) { $script:failures += $msg; Write-Host "FAIL $msg" -ForegroundColor Red }
function Ok([string]$msg)   { Write-Host "OK   $msg" -ForegroundColor Green }

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Fail 'docker CLI not found - install Docker Desktop first.'
} else {
    docker compose version | Out-Null
    if ($LASTEXITCODE -ne 0) { Fail 'docker compose plugin is not available.' }
}

# .env: prefer the real one, fall back to the template (CI does the same).
if (Test-Path .env) { $envFile = '.env'; Ok '.env present' }
elseif (Test-Path .env.example) { $envFile = '.env.example'; Ok '.env.example present (.env missing - using the template)' }
else { $envFile = $null; Fail 'neither .env nor .env.example exists' }

if ($failures.Count -eq 0) {
    docker compose --env-file $envFile config -q
    if ($LASTEXITCODE -eq 0) { Ok 'docker compose config parses' }
    else { Fail 'docker compose config failed (see output above)' }

    $services = @(docker compose --env-file $envFile config --services 2>$null | Where-Object { $_ -and $_.Trim() })
    foreach ($s in 'postgres','ms-auth','microservicio-practica','ms-frontend') {
        if ($services -contains $s) { Ok "service $s declared" } else { Fail "service $s missing" }
    }
    if ($services.Count -ne 4) { Fail "expected 4 services, found $($services.Count)" }

    foreach ($v in 'APP_JWT_SECRET_MASTER','APP_JWT_SECRET_SESSION') {
        $line = Select-String -Path $envFile -Pattern "^$v=" | Select-Object -First 1
        if (-not $line) { Fail "$v missing in $envFile"; continue }
        $value = ($line.Line -split '=', 2)[1].Trim()
        if ($value.Length -ge 32) { Ok "$v length $($value.Length) (>= 32)" }
        else { Fail "$v length $($value.Length) - ms-auth fails fast under 32" }
    }

    # Build contexts only exist on a workstation with the siblings cloned next to this repo.
    foreach ($sibling in 'ms-auth','practica','ms-frontend') {
        $path = Join-Path (Split-Path -Parent (Get-Location).Path) $sibling
        if (Test-Path $path) { Ok "sibling $sibling found (build context)" }
        else { Write-Host "WARN sibling $sibling not cloned - 'docker compose up --build' will fail here" -ForegroundColor Yellow }
    }
}

if ($failures.Count -gt 0) {
    Write-Host "`n$($failures.Count) check(s) failed." -ForegroundColor Red
    exit 1
}
Write-Host "`nCompose contract OK (images not built - CI green != stack verified)." -ForegroundColor Green

