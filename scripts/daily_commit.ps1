$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

$linksPath = Join-Path $repoRoot "links.txt"
$readmePath = Join-Path $repoRoot "README.md"

if (!(Test-Path $linksPath)) {
  Write-Error "links.txt not found at $linksPath"
  exit 1
}

if (!(Test-Path $readmePath)) {
  Write-Error "README.md not found at $readmePath"
  exit 1
}

$links = Get-Content $linksPath | Where-Object {
  $_ -and $_.Trim() -ne "" -and $_ -notmatch '^\s*#'
}

if ($links.Count -eq 0) {
  Write-Error "No usable links found in links.txt"
  exit 1
}

$index = ((Get-Date).DayOfYear - 1) % $links.Count
$link = $links[$index].Trim()

$readme = Get-Content $readmePath -Raw
$dateStamp = Get-Date -Format 'yyyy-MM-dd'
$pattern = '\[DailyVocaloid\]\([^\)]*\)(?:\s+-\s+\d{4}-\d{2}-\d{2})?'
$replacement = "[DailyVocaloid]($link) - $dateStamp"

if ($readme -match $pattern) {
  $updated = [regex]::Replace($readme, $pattern, $replacement, 1)
} else {
  $updated = $readme.TrimEnd() + "`r`n`r`n$replacement`r`n"
}

if ($updated -ne $readme) {
  Set-Content -Path $readmePath -Value $updated -NoNewline -Encoding UTF8
}

& git diff --quiet -- README.md
if ($LASTEXITCODE -eq 0) {
  Write-Host "No README.md changes to commit."
  exit 0
}

$commitMsg = "daily vocaloid: $dateStamp"

& git add README.md
& git commit -m $commitMsg
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

& git push origin main
