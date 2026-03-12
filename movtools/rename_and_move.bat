@echo off
setlocal enabledelayedexpansion

REM rename_and_move.bat
REM 1) read extract_movinfo.csv (id,title,country)
REM 2) read extract_mov_folder_info.csv (folder,file)
REM 3) for each folder, map numeric id -> title+country, create target folder
REM 4) move files to target folder and rename to Title+Country.ext

chcp 936>nul 2>nul

set "SDIR=%~dp0"
set "MEDCSV=%SDIR%extract_movinfo.csv"
set "FOLDCSV=%SDIR%extract_mov_folder_info.csv"
set "MAPFILE=%SDIR%map_id_name.tmp"

rem Accept optional root folder as first arg (mimics extract_mov_folder_info.bat)
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

:: remove last slash if exists
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
echo Root folder: %ROOT%

if not exist "%MEDCSV%" (
  echo Error: %MEDCSV% not found
  pause
  exit /b 1
)
if not exist "%FOLDCSV%" (
  echo Error: %FOLDCSV% not found
  pause
  exit /b 1
)

if exist "%MAPFILE%" del "%MAPFILE%" 2>nul

:: remove slash from root if exists
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
echo Root folder: %ROOT%

echo Building mapping from %MEDCSV% ...
if exist "%MAPFILE%" del "%MAPFILE%" 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%SDIR%make_map.ps1" -medcsv "%MEDCSV%" -mapfile "%MAPFILE%"
if errorlevel 1 (
  echo Error: make_map.ps1 failed with exit code %errorlevel%
)
if exist "%MAPFILE%" (
  echo DBG: mapfile created: %MAPFILE%
  type "%MAPFILE%"
) else (
  echo DBG: mapfile NOT created: %MAPFILE%
)

echo Processing folders from %FOLDCSV% ...
REM Use PowerShell to perform moves reliably (handles Unicode and quoted CSV)
set "PS_CMD=powershell -NoProfile -ExecutionPolicy Bypass -File "%SDIR%move_by_info.ps1" -Root "%ROOT%" -FoldCsv "%FOLDCSV%" -MedCsv "%MEDCSV%""
rem Only enable DryRun when DRYRUN is explicitly "1" or "true" (case-insensitive)
if /I "%DRYRUN%"=="1" (
  set "PS_CMD=%PS_CMD% -DryRun"
) else if /I "%DRYRUN%"=="true" (
  set "PS_CMD=%PS_CMD% -DryRun"
)
echo Calling: %PS_CMD%
%PS_CMD%
echo Finished moves.

echo Cleaning up empty source folders (remove only if empty)...
set "DEL_CMD=powershell -NoProfile -ExecutionPolicy Bypass -File "%SDIR%delete_empty_sources.ps1" -Root "%ROOT%" -FoldCsv "%FOLDCSV%""
rem Only enable DryRun for delete when DRYRUN is explicitly "1" or "true"
if /I "%DRYRUN%"=="1" (
  set "DEL_CMD=%DEL_CMD% -DryRun"
) else if /I "%DRYRUN%"=="true" (
  set "DEL_CMD=%DEL_CMD% -DryRun"
)
echo Calling: %DEL_CMD%
%DEL_CMD%

echo Done.
exit /b 0

:prepare_folder
setlocal enabledelayedexpansion
set "fld=%~1"
REM strip leading zeros to numeric id
set "nid=%fld%"
:strip0
if "%nid:~0,1%"=="0" (
  set "nid=%nid:~1%"
  goto :strip0
)
if "%nid%"=="" set "nid=0"

set "found="
for /f "usebackq tokens=1* delims=|" %%M in ("%MAPFILE%") do (
  if "%%~M"=="%nid%" (
    set "found=%%~N"
  )
)
if not defined found (
  echo Warning: no mapping for id %nid% (folder %fld%)
  endlocal & set "MAP_%fld%="
  goto :eof
)
set "target=%ROOT%\%found%"
if not exist "%target%" (
  mkdir "%target%"
)
endlocal & set "MAP_%fld%=%found%"
goto :eof

:ext_of
setlocal enabledelayedexpansion
set "fname=%~1"
for %%x in ("%fname%") do set "e=%%~xx"
endlocal & set "%~2=%e%"
goto :eof

:move_file
REM signature: %~1 = source absolute path, %~2 = destination absolute path
setlocal enabledelayedexpansion
set "src=%~1"
set "dst=%~2"
if exist "%src%" (
  echo Moving "%src%" -> "%dst%"
  move "%src%" "%dst%" >nul 2>&1
  if errorlevel 1 (
    echo Move failed, trying copy: "%src%" -> "%dst%"
    copy /y "%src%" "%dst%" >nul 2>&1 && del "%src%"
  )
) else (
  echo Source missing: "%src%"
)
endlocal
goto :eof

:make_name
setlocal enabledelayedexpansion
set "t=%~1+%~2"
set "t=!t:/=_!"
set "t=!t:\=_!"
set "t=!t::=_!"
set "t=!t:*=_!"
set "t=!t:?=_!"
set "t=!t:<=_!"
set "t=!t:>=_!"
set "t=!t:|=_!"
for /f "tokens=* delims= " %%z in ("!t!") do set "t=%%z"
endlocal & set "name=%t%"
goto :eof
