<#
.SYNOPSIS
  Delete source folders listed in a CSV when they are empty.

.DESCRIPTION
  Reads a folder CSV (same format as extract_mov_folder_info.csv), for each folder
  checks if the folder exists and contains any files. If the folder contains no
  files (and no child items), it is deleted. Use -DryRun to preview removals.

.PARAMETER Root
  Root path containing the numeric folders (e.g. F:)

.PARAMETER FoldCsv
  Path to the CSV file listing folder rows (first column is folder name)

.PARAMETER DryRun
  If specified, only lists folders that would be removed.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Root = (Get-Location).ProviderPath,

    [Parameter(Mandatory=$true)]
    [string]$FoldCsv,

    [switch]$DryRun
)

try {
    if (-not (Test-Path -LiteralPath $FoldCsv)) {
        Write-Error "FoldCsv not found: $FoldCsv"
        exit 1
    }

    # Normalize root: remove trailing backslash
    if ($Root -and $Root.EndsWith('\')) { $Root = $Root.TrimEnd('\') }

    # Auto-detect delimiter (pipe '|' or comma ',') then import CSV.
    $allLines = Get-Content -LiteralPath $FoldCsv -ErrorAction Stop
    if ($allLines.Count -eq 0) { Write-Output "FoldCsv is empty: $FoldCsv"; exit 0 }
    $sampleLines = if ($allLines.Count -gt 1) { $allLines[1..[math]::Min($allLines.Count-1,10)] } else { @() }
    $pipeCount = ($sampleLines | Where-Object { $_ -match '\|' }).Count
    $commaCount = ($sampleLines | Where-Object { $_ -match ',' }).Count
    if ($pipeCount -gt $commaCount) { $delim = '|' } else { $delim = ',' }
    $rows = Import-Csv -Path $FoldCsv -Delimiter $delim -Header Folder,File -ErrorAction Stop
    foreach ($r in $rows) {
        $fld = $r.Folder
        Write-Output "Processing row: Folder='$fld' File='$($r.File)'"
        if ($null -eq $fld) { continue }
        $fld = $fld.Trim('"').Trim()
        # Skip header-like rows that don't contain digits
        if ($fld -notmatch '\d') { continue }

        $folderPath = Join-Path -Path $Root -ChildPath $fld
        Write-Output "Checking: $folderPath"

        if (-not (Test-Path -LiteralPath $folderPath)) {
            Write-Output "Missing: $folderPath"
            continue
        }

        # Check for any files (including in subdirectories). Hidden/system files count.
        $children = Get-ChildItem -LiteralPath $folderPath -File -Recurse -Force -ErrorAction SilentlyContinue
        if ($children.Count -eq 0) {
            if ($DryRun) {
                Write-Output "Would remove: $folderPath"
            } else {
                try {
                    Remove-Item -LiteralPath $folderPath -Recurse -Force -ErrorAction Stop
                    Write-Output "Removed: $folderPath"
                } catch {
                    Write-Error "Failed to remove: $folderPath — $_"
                }
            }
        } else {
            Write-Output "Keeping (contains files): $folderPath"
        }
    }
} catch {
    Write-Error "Error: $_"
    exit 1
}

exit 0
