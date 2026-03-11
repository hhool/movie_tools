@echo off
setlocal enabledelayedexpansion

REM Paths (script directory)
set "SDIR=%~dp0"
set "FOLDCSV=%SDIR%extract_mov_folder_info.csv"
set "FOLDSUM=%SDIR%extract_mov_folder_info_summary.csv"
set "MEDCSV=%SDIR%MediaLibnew.csv"
set "OUT=%SDIR%extract_movinfo.csv"
set "SUM=%SDIR%extract_movinfo_summary.csv"

REM Validate input files
if not exist "%FOLDCSV%" (
  echo Error: %FOLDCSV% not found
  exit /b 1
)
REM FOLDCSV is required for folder scanning results.
if not exist "%FOLDSUM%" (
  echo Error: %FOLDSUM% not found
  exit /b 1
)

REM MediaLibnew.csv is optional, but if it exists, it must be valid for extraction
if not exist "%MEDCSV%" (
  echo Error: %MEDCSV% not found
  exit /b 1
)

set "min="
set "max="

REM Read folder min and max from FOLDSUM (min,max)
::Min Folder|Max Folder
::000000005,000000040
for /f "usebackq tokens=1,2 delims=," %%A in ("%FOLDSUM%") do (
  set "min=%%~A"
  set "max=%%~B"
  echo Read from summary: min=!min!, max=!max!
  :: Validate that min and max are numeric
  set "isnum_min=1"
  for /f "delims=0123456789" %%x in ("!min!") do set "isnum_min=0"
  set "isnum_max=1"
  for /f "delims=0123456789" %%x in ("!max!") do set "isnum_max=0"
  if "!isnum_min!"=="0" (
    :: continue to next line if not numeric
    echo Warning: min value !min! is not numeric, skipping.
    set "min="
  )
  if "!isnum_max!"=="0" (
    :: continue to next line if not numeric
    echo Warning: max value !max! is not numeric, skipping.
    set "max="
  )
)

echo Final min: %min%, max: %max%

REM Strip leading zeros from min/max to create numeric comparison values
set "minNum=%min%"
set "maxNum=%max%"
:_strip_min
if "%minNum:~0,1%"=="0" (
  set "minNum=%minNum:~1%"
  goto :_strip_min
)
if "%minNum%"=="" set "minNum=0"
:_strip_max
if "%maxNum:~0,1%"=="0" (
  set "maxNum=%maxNum:~1%"
  goto :_strip_max
)
if "%maxNum%"=="" set "maxNum=0"

REM Validate min and max values
if not defined min (
  echo No min value found in %FOLDSUM%
  exit /b 1
)
if not defined max (
  echo No max value found in %FOLDSUM%
  exit /b 1
)

echo Found range: %min% - %max% (numeric %minNum% - %maxNum%)

REM Prepare outputs
if exist "%OUT%" del "%OUT%" 2>nul
if exist "%SUM%" del "%SUM%" 2>nul

set /a count=0

REM Copy header from MediaLibnew or create header
for /f "usebackq delims=" %%L in ("%MEDCSV%") do (
  set "firstline=%%L"
  goto :got_header
)
:got_header
echo %firstline%>"%OUT%"

REM Extract lines from MediaLibnew where id between min and max (inclusive)
for /f "usebackq skip=1 tokens=1* delims=," %%A in ("%MEDCSV%") do (
  set "id=%%~A"
  set "line=%%~A,%%~B"
  set /a iid=%%~A 2>nul || (set "iid=-1")
  if defined minNum if defined maxNum (
    if !iid! GEQ %minNum% if !iid! LEQ %maxNum% (
      >>"%OUT%" echo(!line!
      set /a count+=1
    )
  )
)

REM Write summary CSV (key,value)
echo key,value>"%SUM%"
echo min,%min%>>"%SUM%"
echo max,%max%>>"%SUM%"
echo records,%count%>>"%SUM%"

echo Done. Extracted %count% records to %OUT%
echo Summary written to %SUM%
exit /b 0
