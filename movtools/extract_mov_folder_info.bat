@echo off
setlocal enabledelayedexpansion

REM Ensure OEM code page for Chinese display
chcp 936>nul 2>nul

if "%~1"=="" (
  set "ROOT=%cd%"
) else (
  set "ROOT=%~1"
)

:: Validate root folder
if not exist "%ROOT%\" (
  echo Error: invalid folder path: %ROOT%
  pause
  exit /b 1
)

::remove last slash if exists
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
echo Scanning root folder: %ROOT%
set "OUT=%~dp0\extract_mov_folder_info.csv"
set "OUT_SUMMARY=%~dp0\extract_mov_folder_info_summary.csv"

:: Clean up old output file if exists
if exist "%OUT%" del "%OUT%" 2>nul
if exist "%OUT_SUMMARY%" del "%OUT_SUMMARY%" 2>nul

:: Write header to output CSV
echo Folder^|File>"%OUT%"
echo Min Folder^|Max Folder>"%OUT_SUMMARY%"

:: Scan folders and files
:: min_folder_name and max_folder_name used to track numeric folder names.
set "min_folder_name="
set "max_folder_name="
for /d %%D in ("%ROOT%\*") do (
  set "folder=%%~nD"
  echo Processing folder: !folder!
  REM Check if folder name is numeric
  set "isnum=1"
  for /f "delims=0123456789" %%x in ("!folder!") do set "isnum=0"
  :: If numeric, track min and max folder names for summary output.
  if "!isnum!"=="1" (
    echo Folder !folder! is numeric.
    :: Update min and max folder names
    if not defined min_folder_name set "min_folder_name=!folder!"
      set "max_folder_name=!folder!"
    ) else (
        echo Folder !folder! is not numeric, skipping range tracking.
        :: Non-numeric folder, skip range tracking, not scanned for files.
        goto :continue
    )
    :: Scan files in the folder
    echo Scanning files in folder: "%ROOT%\%%~nD"
    for /f "usebackq delims=" %%F in (`dir /b /a:-d "%ROOT%\%%~nD\*" 2^>nul`) do (
        set "file=%%F"
        echo Found file: !file! in folder: !folder!
        setlocal enabledelayedexpansion
        >>"%OUT%" echo(!folder!,!file!
        endlocal
    )
  )
  :continue
  >>"%OUT_SUMMARY%" echo(!min_folder_name!,!max_folder_name!
)

echo Done. Output: %OUT%
exit /b 0
