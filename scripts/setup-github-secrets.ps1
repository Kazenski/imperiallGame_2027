# Configura os GitHub Secrets do repositorio a partir do arquivo .env local.
# Os valores NUNCA sao exibidos no terminal.
#
# Uso:
#   .\scripts\setup-github-secrets.ps1
#   .\scripts\setup-github-secrets.ps1 -EnvFile .env -Repo Kazenski/imperiallGame_2027

[CmdletBinding()]
param(
    [string]$EnvFile = ".env",
    [string]$Repo = "Kazenski/imperiallGame_2027"
)

$ErrorActionPreference = 'Stop'

function Require-Command($name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "Comando '$name' nao encontrado. Instale o GitHub CLI: https://cli.github.com"
    }
}

Require-Command git
Require-Command gh

Write-Host "Verificando autenticacao do GitHub CLI..." -ForegroundColor Cyan
gh auth status | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Faca 'gh auth login' primeiro." }

$root = if (Test-Path (Join-Path $PSScriptRoot '..\.git')) { (Resolve-Path (Join-Path $PSScriptRoot '..')).Path } else { (Get-Location).Path }
$envPath = if ([System.IO.Path]::IsPathRooted($EnvFile)) { $EnvFile } else { Join-Path $root $EnvFile }

if (-not (Test-Path $envPath)) {
    Write-Warning "Arquivo '$envPath' nao encontrado."
    Write-Host "Copie .env.example para .env e preencha os valores. Nada foi alterado."
    exit 1
}

# Falha cedo se o .env nao estiver ignorado pelo git.
Push-Location $root
git check-ignore -q $envPath
$ignored = ($LASTEXITCODE -eq 0)
Pop-Location

if (-not $ignored) {
    Write-Warning "ATENCAO: '$envPath' NAO esta no .gitignore!"
    Write-Warning "Adicione '.env' ao .gitignore ANTES de continuar. Abortando por seguranca."
    exit 1
}

# Le e parseia o .env
$vars = @{}
foreach ($line in Get-Content $envPath) {
    $t = $line.Trim()
    if ($t -eq '' -or $t.StartsWith('#')) { continue }
    if ($t -match '^(?<k>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?<v>.*)$') {
        $vars[$Matches['k']] = $Matches['v'].Trim().Trim('"').Trim("'")
    }
}

$allowed = @('SUPABASE_URL', 'SUPABASE_ANON_KEY')
$keys = @()

foreach ($k in $allowed) {
    if ($vars.ContainsKey($k) -and -not [string]::IsNullOrWhiteSpace($vars[$k])) {
        $keys += $k
    }
}

# Secrets opcionais de assinatura (variaveis de ambiente do shell)
$signing = @('ANDROID_KEYSTORE_BASE64', 'ANDROID_KEYSTORE_PASSWORD', 'ANDROID_KEY_ALIAS', 'ANDROID_KEY_PASSWORD')
foreach ($k in $signing) {
    $val = [Environment]::GetEnvironmentVariable($k)
    if (-not [string]::IsNullOrWhiteSpace($val)) {
        $vars[$k] = $val
        $keys += $k
    }
}

if ($keys.Count -eq 0) {
    Write-Warning "Nenhum valor encontrado para configurar. Preencha o .env primeiro."
    exit 1
}

Write-Host "Repositorio: $Repo" -ForegroundColor Cyan
Write-Host "Secrets a configurar: $($keys -join ', ')" -ForegroundColor Cyan

foreach ($k in $keys) {
    $vars[$k] | gh secret set $k --repo $Repo
    if ($LASTEXITCODE -ne 0) { throw "Falha ao configurar o secret '$k'." }
    Write-Host "  [ok] $k" -ForegroundColor Green
}

Write-Host "`nConcluido. Lista atual:" -ForegroundColor Green
gh secret list --repo $Repo
