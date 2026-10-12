# Adiciona entradas de forma ADITIVA ao CHANGELOG.md.
# Nunca remove nem reescreve entradas existentes.
#
# Uso:
#   .\scripts\new-changelog-entry.ps1 -Category Adicionado -Message "Loja de itens"
#   .\scripts\new-changelog-entry.ps1 -Release 0.2.0
#
# Categorias validas: Adicionado, Alterado, Descontinuado, Removido, Corrigido, Seguranca

[CmdletBinding(DefaultParameterSetName = 'Entry')]
param(
    [Parameter(ParameterSetName = 'Entry')]
    [ValidateSet('Adicionado', 'Alterado', 'Descontinuado', 'Removido', 'Corrigido', 'Seguranca')]
    [string]$Category = 'Adicionado',

    [Parameter(ParameterSetName = 'Entry', Mandatory = $true)]
    [string]$Message,

    [Parameter(ParameterSetName = 'Release', Mandatory = $true)]
    [string]$Release
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $PSScriptRoot '..\CHANGELOG.md'))) { $root = (Get-Location).Path }
$changelog = Join-Path $root 'CHANGELOG.md'

if (-not (Test-Path $changelog)) {
    throw "CHANGELOG.md nao encontrado em $root"
}

$utf8 = New-Object System.Text.UTF8Encoding($false)
$raw = [System.IO.File]::ReadAllText($changelog, [System.Text.Encoding]::UTF8)
$raw = $raw -replace "`r`n", "`n"
$lines = [System.Collections.Generic.List[string]]($raw -split "`n")

$unreleasedIdx = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^##\s+\[N[ãa]o publicado\]') { $unreleasedIdx = $i; break }
}

if ($unreleasedIdx -lt 0) {
    throw "Secao '## [Nao publicado]' nao encontrada. Crie-a no topo do CHANGELOG antes de continuar."
}

# ---------- Modo: criar release ----------
if ($PSCmdlet.ParameterSetName -eq 'Release') {
    $today = Get-Date -Format 'yyyy-MM-dd'
    $lines[$unreleasedIdx] = "## [$Release] - $today"

    $header = [System.Collections.Generic.List[string]]@(
        '## [Nao publicado]',
        '',
        '### Adicionado',
        ''
    )
    # Insere a nova secao logo acima da versao recem-fechada
    $lines.InsertRange($unreleasedIdx, $header)

    [System.IO.File]::WriteAllText($changelog, ($lines -join "`n"), $utf8)
    Write-Host "Release $Release criada. Nova secao '## [Nao publicado]' adicionada no topo." -ForegroundColor Green
    return
}

# ---------- Modo: adicionar entrada ----------
# Encontra o fim da secao "Nao publicado" (proxima linha "## ")
$sectionEnd = $lines.Count
for ($i = $unreleasedIdx + 1; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^##\s+') { $sectionEnd = $i; break }
}

$catIdx = -1
for ($i = $unreleasedIdx + 1; $i -lt $sectionEnd; $i++) {
    if ($lines[$i] -match "^\s*###\s+$Category\s*$") { $catIdx = $i; break }
}

$bullet = "- $Message"

if ($catIdx -ge 0) {
    # Insere o bullet logo apos o cabecalho da categoria
    $lines.Insert($catIdx + 1, $bullet)
    Write-Host "Entrada adicionada em '$Category'." -ForegroundColor Green
}
else {
    # Cria a categoria logo antes do fim da secao Nao publicado
    $insertAt = $sectionEnd
    while ($insertAt -gt $unreleasedIdx + 1 -and [string]::IsNullOrWhiteSpace($lines[$insertAt - 1])) {
        $insertAt--
    }
    $block = [System.Collections.Generic.List[string]]@('', "### $Category", $bullet)
    $lines.InsertRange($insertAt, $block)
    Write-Host "Categoria '$Category' criada em '[Nao publicado]'." -ForegroundColor Green
}

[System.IO.File]::WriteAllText($changelog, ($lines -join "`n"), $utf8)
Write-Host "CHANGELOG.md atualizado (aditivo)." -ForegroundColor Green
