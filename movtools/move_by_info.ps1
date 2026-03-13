Param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$FoldCsv,
  [Parameter(Mandatory=$true)][string]$MedCsv,
  [switch]$DryRun
)
$ErrorActionPreference = 'Continue'
if (-not (Test-Path $FoldCsv)) { Write-Error "Folder CSV not found: $FoldCsv"; exit 1 }
if (-not (Test-Path $MedCsv)) { Write-Error "Media CSV not found: $MedCsv"; exit 1 }

$headers = 1..50 | ForEach-Object { 'c' + $_ }
# Read media CSV using GBK/GB2312 encoding to preserve Chinese characters
$enc = [System.Text.Encoding]::GetEncoding(936)
$lines = [System.IO.File]::ReadAllLines($MedCsv, $enc)
$med = $lines | ConvertFrom-Csv -Header $headers -Delimiter ',' | Where-Object { $_.c1 }
$medIndex = @{ }
foreach ($r in $med) {
  $key = $r.c1.ToString().Trim()
  if (-not $medIndex.ContainsKey($key)) { $medIndex[$key] = $r }
}

# Read folder CSV lines (skip header if present)
$lines = Get-Content -Path $FoldCsv -Encoding UTF8
if ($lines.Count -gt 0 -and ($lines[0] -match "[Ff]older|[Ff]ile")) { $lines = $lines | Select-Object -Skip 1 }

foreach ($ln in $lines) {
  if ($ln.Trim() -eq '') { continue }
  # Accept comma-delimited lines; ignore stray separators
  $parts = $ln -split ","
  if ($parts.Count -lt 2) { continue }
  $folder = $parts[0].Trim()
  $file = $parts[1].Trim()
  if ($folder -eq '') { continue }
  # strip leading zeros to numeric id
  $nid = $folder.TrimStart('0')
  if ($nid -eq '') { $nid = '0' }
  if (-not $medIndex.ContainsKey($nid)) {
    Write-Host "Warning: no mapping for id $nid (folder $folder)"
    continue
  }
  $r = $medIndex[$nid]
  $titleZh = ($r.c3 -as [string]).Trim()
  $titleEn = ($r.c11 -as [string]).Trim()
  $country = ($r.c15 -as [string]).Trim()
  $release = ($r.c12 -as [string]).Trim()
  $year = ''
  if ($release -match '^(\d{4})') { $year = $Matches[1] }

  $parts = @()
  if ($titleZh -ne '') { $parts += $titleZh }
  if ($titleEn -ne '') { $parts += $titleEn }
  if ($country -ne '') { $parts += $country }
  if ($year -ne '') { $parts += $year }

  if ($parts.Count -eq 0) { Write-Host "Warning: empty basename for id $nid (folder $folder)"; continue }

  $basename = ($parts -join '-')
  $basename = $basename -replace '[\\/:*?"<>|]', '_' # sanitize
  if ($basename -eq '') { Write-Host "Warning: empty basename for id $nid (folder $folder)"; continue }

  $targetDir = Join-Path -Path $Root -ChildPath $basename
  $src = Join-Path -Path $Root -ChildPath (Join-Path $folder $file)
  $ext = [IO.Path]::GetExtension($file)
  $dst = Join-Path -Path $targetDir -ChildPath ($basename + $ext)

  if ($DryRun) {
    Write-Host "DRYRUN: would move '$src' -> '$dst'"
  } else {
    if (-not (Test-Path $src)) {
      Write-Host "Source missing: $src"
      continue
    }
    if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
    try {
      Move-Item -LiteralPath $src -Destination $dst -Force
      Write-Host "Moved: '$src' -> '$dst'"
    } catch {
      try {
        Copy-Item -LiteralPath $src -Destination $dst -Force
        Remove-Item -LiteralPath $src -Force
        Write-Host "Copied+Removed: '$src' -> '$dst'"
      } catch {
        Write-Host "Failed to move or copy: $src -> $dst ($_ )"
      }
    }
  }
}
exit 0
