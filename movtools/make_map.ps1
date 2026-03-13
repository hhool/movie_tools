Param(
  [Parameter(Mandatory=$true)][string]$medcsv,
  [Parameter(Mandatory=$true)][string]$mapfile
)
$ErrorActionPreference = 'Stop'
$headers = 1..40 | ForEach-Object { 'c' + $_ }
$enc = [System.Text.Encoding]::GetEncoding(936)
try {
  $lines = [System.IO.File]::ReadAllLines($medcsv, $enc)
  $rows = $lines | ConvertFrom-Csv -Header $headers -Delimiter ','
} catch {
  $msg = $_.Exception.Message
  Write-Error ("Failed to read {0}: {1}" -f $medcsv, $msg)
  exit 1
}
$lines = @()
foreach ($r in $rows) {
  if (-not $r.c1) { continue }
  $id = $r.c1.Trim()
  if ($id -eq '') { continue }
  $titleZh = ($r.c3 -as [string]).Trim()
  $titleEn = ($r.c11 -as [string]).Trim()
  $country = ($r.c15 -as [string]).Trim()
  $release = ($r.c12 -as [string]).Trim()
  # extract year from release date like 2001-05-18
  $year = ''
  if ($release -match '^(\d{4})') { $year = $Matches[1] }

  $parts = @()
  if ($titleZh -ne '') { $parts += $titleZh }
  if ($titleEn -ne '') { $parts += $titleEn }
  if ($country -ne '') { $parts += $country }
  if ($year -ne '') { $parts += $year }

  if ($parts.Count -eq 0) { continue }

  $name = ($parts -join '-')
  $name = $name -replace '[\\/:*?"<>|]', '_'
  $name = $name.Trim()
  if ($name -ne '') { $lines += "$id|$name" }
}
if ($lines.Count -gt 0) {
  # Write using system ANSI encoding to avoid BOM/OEM issues when read by CMD
  [System.IO.File]::WriteAllLines($mapfile, $lines, [System.Text.Encoding]::Default)
} else {
  if (Test-Path $mapfile) { Remove-Item $mapfile -ErrorAction SilentlyContinue }
}
exit 0
