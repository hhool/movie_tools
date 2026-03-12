@echo off
setlocal enabledelayedexpansion

rem Unified runner: calls the three scripts in order and keeps console open
set "SDIR=%~dp0"

rem If arguments are provided (drag-drop or explicit parameters), forward them
set "ARGS=%*"
if not "%ARGS%"=="" (
  echo Forwarding arguments to called scripts: %ARGS%
)

echo ==================================================
echo Running all movtools scripts from %SDIR%
echo ==================================================

set "status=0"

echo.
echo 1) Running extract_mov_folder_info.bat
call "%SDIR%extract_mov_folder_info.bat" %ARGS%
set "rc1=%ERRORLEVEL%"
if "%rc1%" NEQ "0" (
  echo Warning: extract_mov_folder_info.bat returned %rc1% (continuing)
  set "status=1"
) else (
  echo extract_mov_folder_info.bat completed successfully
)

echo.
echo 2) Running extract_movinfo.bat
call "%SDIR%extract_movinfo.bat" %ARGS%
set "rc2=%ERRORLEVEL%"
if "%rc2%" NEQ "0" (
  echo Warning: extract_movinfo.bat returned %rc2% (continuing)
  set "status=1"
) else (
  echo extract_movinfo.bat completed successfully
)

echo.
echo 3) Running rename_and_move.bat
call "%SDIR%rename_and_move.bat" %ARGS%
set "rc3=%ERRORLEVEL%"
if "%rc3%" NEQ "0" (
  echo Warning: rename_and_move.bat returned %rc3% (continuing)
  set "status=1"
) else (
  echo rename_and_move.bat completed successfully
)

echo.
if "%status%" NEQ "0" (
  echo One or more scripts exited with errors. See messages above.
) else (
  echo All scripts finished successfully.
)

echo.
echo The console will remain open. Press any key to close.
pause >nul

endlocal
