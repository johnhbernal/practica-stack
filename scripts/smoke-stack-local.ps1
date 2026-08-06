# Smoke without Docker: start auth + practica (dev/H2) + frontend Vite.
# Prerequisites: Temurin 17, Maven wrapper in sibling repos, Node 22+.
# Usage: powershell -File scripts/smoke-stack-local.ps1

$ErrorActionPreference = 'Stop'
$stackRoot = Split-Path -Parent $PSScriptRoot
$proyectos = Split-Path -Parent $stackRoot

$jdk = Join-Path $env:USERPROFILE 'scoop\apps\temurin17-jdk\current'
if (Test-Path (Join-Path $jdk 'bin\java.exe')) {
    $env:JAVA_HOME = $jdk
    $env:Path = "$jdk\bin;" + $env:Path
}

$jobs = @()

function Start-Svc([string]$Name, [string]$Dir, [scriptblock]$Cmd) {
    Write-Host "==> starting $Name" -ForegroundColor Cyan
    $j = Start-Job -Name $Name -ScriptBlock $Cmd -ArgumentList $Dir
    return $j
}

$authJob = Start-Job -Name 'ms-auth' -ScriptBlock {
    param($dir)
    Set-Location $dir
    & .\mvnw.cmd -q spring-boot:run "-Dspring-boot.run.profiles=dev"
} -ArgumentList (Join-Path $proyectos 'ms-auth')

$pracJob = Start-Job -Name 'practica' -ScriptBlock {
    param($dir)
    Set-Location $dir
    & .\mvnw.cmd -q spring-boot:run "-Dspring-boot.run.profiles=dev"
} -ArgumentList (Join-Path $proyectos 'practica')

$frontJob = Start-Job -Name 'ms-frontend' -ScriptBlock {
    param($dir)
    Set-Location $dir
    $env:BROWSER = 'none'
    $env:VITE_AUTH_API_URL = 'http://localhost:8081'
    $env:VITE_PRACTICA_API_URL = 'http://localhost:8082/api'
    npm run dev
} -ArgumentList (Join-Path $proyectos 'ms-frontend')

function Wait-HttpOk([string]$Url, [int]$TimeoutSec = 180) {
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        try {
            $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
            if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 300) {
                Write-Host "OK $Url" -ForegroundColor Green
                return
            }
        } catch { Start-Sleep -Seconds 4 }
    }
    Write-Error "Timeout waiting for $Url"
}

try {
    Wait-HttpOk 'http://localhost:8081/actuator/health' 240
    Wait-HttpOk 'http://localhost:8082/api/actuator/health' 240
    Wait-HttpOk 'http://localhost:3000' 240

    $body = '{"username":"admin","password":"Admin123!"}'
    $login = Invoke-RestMethod -Method Post -Uri 'http://localhost:8081/api/auth/login' `
        -ContentType 'application/json' -Body $body
    Write-Host 'Login OK' -ForegroundColor Green
    Write-Host 'UI http://localhost:3000 — press Ctrl+C in this shell when done; jobs will be stopped.'
    Wait-Job -Any @($authJob, $pracJob, $frontJob) | Out-Null
} finally {
    Get-Job | Stop-Job -ErrorAction SilentlyContinue
    Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue
}
