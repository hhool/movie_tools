@echo off
:: 使用GBK编码（Windows默认）
setlocal enabledelayedexpansion

:: 设置脚本名称和版本
set "SCRIPT_NAME=媒体库重命名工具"
set "VERSION=1.0"
set "REPORT_FILE=rename_report_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
set "REPORT_FILE=!REPORT_FILE: =0!"

:: 显示标题
echo ========================================
echo      %SCRIPT_NAME% v%VERSION%
echo ========================================
echo.

:: 检查是否拖入了文件夹
if "%~1"=="" (
    echo 错误：请将文件夹拖放到本脚本上！
    echo.
    pause
    exit /b 1
)

:: 获取拖入的文件夹路径
set "MEDIA_PATH=%~1"
if not exist "!MEDIA_PATH!\" (
    echo 错误：无效的文件夹路径！
    echo.
    pause
    exit /b 1
)

echo [信息] 媒体库路径：!MEDIA_PATH!
echo.

:: 获取脚本所在目录
set "SCRIPT_DIR=%~dp0"
@echo off
setlocal enabledelayedexpansion

:: Script name and version
set "SCRIPT_NAME=Media Rename Tool"
set "VERSION=1.0"
set "REPORT_FILE=rename_report_%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
set "REPORT_FILE=!REPORT_FILE: =0!"

echo ========================================
echo      %SCRIPT_NAME% v%VERSION%
echo ========================================
echo.

:: Check argument (target folder)
if "%~1"=="" (
    echo Error: Please drag a target folder onto this script or pass as parameter.
    echo.
    pause
    exit /b 1
)

set "MEDIA_PATH=%~1"
if not exist "!MEDIA_PATH!\" (
    echo Error: Invalid folder path: !MEDIA_PATH!
    echo.
    pause
    exit /b 1
)

echo [INFO] Media path: !MEDIA_PATH!
echo.

:: Script directory
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=!SCRIPT_DIR:~0,-1!"
echo [INFO] Script directory: !SCRIPT_DIR!
echo.

:: CSV file location
set "CSV_FILE=!SCRIPT_DIR!\MediaLibnew.csv"
if not exist "!CSV_FILE!" (
    echo Error: MediaLibnew.csv not found in script directory: !SCRIPT_DIR!
    echo.
    pause
    exit /b 1
)

echo [INFO] Found CSV: !CSV_FILE!
echo.

:: ============ Step 1: scan folders ============
echo ============ Step 1: Scan folders ============
echo.

set "folder_count=0"
set "min_folder=999999"
set "max_folder=0"
set "num_folder_count=0"
set "non_num_folder_count=0"
set "num_folder_list="
set "non_num_folder_list="

echo [INFO] Scanning: !MEDIA_PATH!
echo ----------------------------------------

for /d %%d in ("!MEDIA_PATH!\*") do (
    set "folder_name=%%~nxd"
    set /a folder_count+=1

    :: Check numeric folder name
    set "is_number=1"
    for /f "delims=0123456789" %%i in ("!folder_name!") do set "is_number=0"

    if "!is_number!"=="1" (
        set /a num_folder_count+=1
        set "num_folder_list=!num_folder_list! !folder_name!"
        set /a "folder_num=!folder_name! + 0"
        if !folder_num! lss !min_folder! set "min_folder=!folder_num!"
        if !folder_num! gtr !max_folder! set "max_folder=!folder_num!"
        echo [NUM] Name:!folder_name! Num:!folder_num!
    ) else (
        set /a non_num_folder_count+=1
        set "non_num_folder_list=!non_num_folder_list! !folder_name!"
        echo [SKIP] Non-numeric: !folder_name!
    )
)

echo ----------------------------------------
echo.

echo [STATS] Total folders: %folder_count%
echo [STATS] Numeric folders: %num_folder_count%
echo [STATS] Non-numeric folders: %non_num_folder_count%

if %num_folder_count% equ 0 (
    echo [ERROR] No numeric folders found; aborting.
    pause
    exit /b 1
)

echo.
echo [RANGE] Min: %min_folder%
echo [RANGE] Max: %max_folder%
set /a "range_size=!max_folder! - !min_folder! + 1"
echo [RANGE] Range size: !range_size! (positions)
echo [RANGE] Actual numeric folders: !num_folder_count!
set /a "missing_count=!range_size! - !num_folder_count!"
echo [RANGE] Missing count: !missing_count!

echo.
echo ============ Step 2: Read CSV ============
echo.

echo [INFO] Reading CSV database...
set "TEMP_CSV=%temp%\media_data_%random%.tmp"

set "line_count=0"
set "csv_id_list="
echo [DEBUG] Start parsing CSV...
echo.

(for /f "usebackq tokens=1-18 delims=," %%a in ("!CSV_FILE!") do (
    set /a line_count+=1
    set "col1=%%a"
    set "col2=%%b"
    set "col3=%%c"
    set "col4=%%d"
    set "col5=%%e"
    set "col6=%%f"
    set "col7=%%g"
    set "col8=%%h"
    set "col9=%%i"
    set "col10=%%j"
    set "col11=%%k"
    set "col12=%%l"
    set "col13=%%m"
    set "col14=%%n"
    set "col15=%%o"
    set "col16=%%p"
    set "col17=%%q"
    set "col18=%%r"

    :: Remove quotes
    set "col1=!col1:"=!"
    set "col3=!col3:"=!"
    set "col11=!col11:"=!"
    set "col15=!col15:"=!"
    set "col16=!col16:"=!"

    :: Trim leading spaces
    for /f "tokens=* delims= " %%i in ("!col1!") do set "col1=%%i"
    for /f "tokens=* delims= " %%i in ("!col3!") do set "col3=%%i"
    for /f "tokens=* delims= " %%i in ("!col11!") do set "col11=%%i"
    for /f "tokens=* delims= " %%i in ("!col15!") do set "col15=%%i"
    for /f "tokens=* delims= " %%i in ("!col16!") do set "col16=%%i"

    set /a "csv_num=!col1! + 0"

    if "!col3!"=="" (
        set "movie_name=!col11!"
    ) else (
        set "movie_name=!col3!"
    )

    if "!movie_name!"=="" set "movie_name=Unknown"

    set "country=!col15!"
    echo !country! | findstr /i "http://" >nul && set "country=Unknown"
    echo !country! | findstr /i "https://" >nul && set "country=Unknown"
    echo !country! | findstr /i "www." >nul && set "country=Unknown"
    echo !country! | findstr /i ".jpg" >nul && set "country=Unknown"
    echo !country! | findstr /i ".png" >nul && set "country=Unknown"
    echo !country! | findstr /i ".gif" >nul && set "country=Unknown"
    echo !country! | findstr /i ".bmp" >nul && set "country=Unknown"
    if "!country!"=="" set "country=Unknown"

    set /a "mod=!line_count! %% 10"
    if !mod! equ 0 (
        echo [PROGRESS] Read !line_count! lines...
    )

    if !line_count! leq 50 (
        echo [DEBUG] Line!line_count!: ID=!col1!, Title="!movie_name!", Country="!country!"
    )

    echo !csv_num!^|!col1!^|!movie_name!^|!country!>> "!TEMP_CSV!"
    set "csv_id_list=!csv_id_list! !csv_num!"
)) 2>nul

echo.
echo [INFO] CSV lines read: %line_count%
echo.

if !line_count! gtr 0 (
    set "csv_min=999999"
    set "csv_max=0"
    for %%i in (%csv_id_list%) do (
        if %%i lss !csv_min! set "csv_min=%%i"
        if %%i gtr !csv_max! set "csv_max=%%i"
    )
    echo [CSV] ID range: !csv_min! ~ !csv_max!
    echo [CSV] Count: %line_count%
)

echo.
echo ============ Step 3: Match CSV to range ============
echo.

echo [INFO] Matching CSV for range !min_folder! ~ !max_folder!...

set "matched_count=0"
set "unmatched_count=0"
set "expected_count=!range_size!"

echo [MATCH] Expected rows: !expected_count! (from !min_folder! to !max_folder!)
echo [MATCH] CSV rows: %line_count%
echo.

set "MATCHED_CSV=%temp%\matched_data_%random%.tmp"
if exist "!MATCHED_CSV!" del "!MATCHED_CSV!"

echo [INFO] Sequentially matching CSV...
echo ----------------------------------------

for /l %%i in (!min_folder!,1,!max_folder!) do (
    set "found=0"
    for /f "tokens=1-4 delims=|" %%a in ('type "!TEMP_CSV!" 2^>nul') do (
        if %%i equ %%a (
            set "found=1"
            set "original_id=%%b"
            set "movie=%%c"
            set "country=%%d"
            echo [MATCH OK] Num:%%i - Original:%%b - Title:%%c - Country:%%d
            echo %%i^|%%b^|%%c^|%%d>> "!MATCHED_CSV!"
            set /a matched_count+=1
        )
    )
    if !found! equ 0 (
        echo [MATCH FAIL] Num:%%i - no CSV data (use Unknown)
        echo %%i^|%%i^|Unknown^|Unknown>> "!MATCHED_CSV!"
        set /a unmatched_count+=1
    )
)

echo ----------------------------------------
echo.

echo [RESULT] Matched: !matched_count!
echo [RESULT] Unmatched: !unmatched_count!
echo [RESULT] Matched file: !MATCHED_CSV!

echo.
echo [PREVIEW] First 20 lines of matched file:
if exist "!MATCHED_CSV!" (
    type "!MATCHED_CSV!" | findstr /n . | findstr /b "[1-20]:"
) else (
    echo [ERROR] Matched file not created!
    pause
    exit /b 1
)
echo.

echo.
echo [NOTICE] There are !unmatched_count! IDs without CSV data.
echo [NOTICE] Those folders will be named "Unknown+Unknown" if missing.
echo.
set /p "confirm=Start processing matched folders? (Y/N): "
if /i not "!confirm!"=="Y" (
    echo User cancelled.
    if exist "!TEMP_CSV!" del "!TEMP_CSV!"
    if exist "!MATCHED_CSV!" del "!MATCHED_CSV!"
    pause
    exit /b 0
)
echo.

echo ============ Step 4: Process folders ============
echo.

echo ======================================== > "!REPORT_FILE!"
echo    %SCRIPT_NAME% Processing Report >> "!REPORT_FILE!"
echo ======================================== >> "!REPORT_FILE!"
echo Time: %date% %time% >> "!REPORT_FILE!"
echo Media path: !MEDIA_PATH! >> "!REPORT_FILE!"
echo CSV file: !CSV_FILE! >> "!REPORT_FILE!"
echo. >> "!REPORT_FILE!"
echo [Scan] Total folders: %folder_count% >> "!REPORT_FILE!"
echo [Scan] Numeric folders: %num_folder_count% >> "!REPORT_FILE!"
echo [Scan] Range: %min_folder% ~ %max_folder% >> "!REPORT_FILE!"
echo [Scan] Range size: !range_size! >> "!REPORT_FILE!"
echo [Scan] CSV rows: %line_count% >> "!REPORT_FILE!"
echo [Match] Matched: !matched_count! >> "!REPORT_FILE!"
echo [Match] Unmatched: !unmatched_count! >> "!REPORT_FILE!"
echo. >> "!REPORT_FILE!"

set "processed_folders=0"
set "renamed_folders=0"
set "renamed_files=0"
set "total_errors=0"

echo [INFO] Processing range !min_folder! to !max_folder! ...
echo.

for /l %%i in (!min_folder!,1,!max_folder!) do (
    set "folder_path=!MEDIA_PATH!\%%i"
    if exist "!folder_path!\" (
        echo [PROCESS] Handling folder: %%i
        echo [PROCESS] Path: !folder_path!
        set "found=0"
        for /f "tokens=1-4 delims=|" %%a in ('type "!MATCHED_CSV!" 2^>nul') do (
            if %%i equ %%a (
                set "found=1"
                set "original_id=%%b"
                set "movie_name=%%c"
                set "country=%%d"
                if "!movie_name!"=="Unknown" echo   [WARN] No title in CSV; using Unknown
                if "!country!"=="Unknown" echo   [WARN] No country in CSV; using Unknown
                set "new_folder_name=!movie_name!+!country!"
                echo   [INFO] New folder name: !new_folder_name!
                set "file_count=0"
                if exist "!folder_path!\001" (
                    set "new_file_name=!new_folder_name!.mp4"
                    echo   [ACTION] Rename video: 001 -> !new_file_name!
                    ren "!folder_path!\001" "!new_file_name!" 2>nul
                    if !errorlevel! equ 0 (
                        echo   [OK] Video renamed
                        echo   [OK] Video: 001 -> !new_file_name! >> "!REPORT_FILE!"
                        set /a file_count+=1
                        set /a renamed_files+=1
                    ) else (
                        echo   [FAIL] Video rename failed, error: !errorlevel!
                        echo   [FAIL] Video: 001 >> "!REPORT_FILE!"
                        set /a total_errors+=1
                    )
                ) else (
                    echo   [INFO] No 001 video file
                )
                if exist "!folder_path!\001.srt" (
                    set "new_sub_name=!new_folder_name!.srt"
                    echo   [ACTION] Rename subtitle: 001.srt -> !new_sub_name!
                    ren "!folder_path!\001.srt" "!new_sub_name!" 2>nul
                    if !errorlevel! equ 0 (
                        echo   [OK] Subtitle renamed
                        echo   [OK] Subtitle: 001.srt -> !new_sub_name! >> "!REPORT_FILE!"
                        set /a file_count+=1
                        set /a renamed_files+=1
                    ) else (
                        echo   [FAIL] Subtitle rename failed, error: !errorlevel!
                        echo   [FAIL] Subtitle: 001.srt >> "!REPORT_FILE!"
                        set /a total_errors+=1
                    )
                ) else (
                    echo   [INFO] No 001.srt subtitle
                )
                if not "%%i"=="!new_folder_name!" (
                    echo   [ACTION] Rename folder: %%i -> !new_folder_name!
                    ren "!folder_path!" "!new_folder_name!" 2>nul
                    if !errorlevel! equ 0 (
                        echo   [OK] Folder renamed
                        echo   [OK] Folder: %%i -> !new_folder_name! >> "!REPORT_FILE!"
                        set /a renamed_folders+=1
                    ) else (
                        echo   [FAIL] Folder rename failed, error: !errorlevel!
                        echo   [FAIL] Folder: %%i >> "!REPORT_FILE!"
                        set /a total_errors+=1
                    )
                ) else (
                    echo   [INFO] Folder name unchanged
                )
                set /a processed_folders+=1
            )
        )
        echo.
    ) else (
        echo [SKIP] Folder does not exist: %%i
        echo [SKIP] Folder does not exist: %%i >> "!REPORT_FILE!"
    )
)

if exist "!TEMP_CSV!" del "!TEMP_CSV!"
if exist "!MATCHED_CSV!" del "!MATCHED_CSV!"

echo. >> "!REPORT_FILE!"
echo ======================================== >> "!REPORT_FILE!"
echo Summary >> "!REPORT_FILE!"
echo ======================================== >> "!REPORT_FILE!"
echo Processed folders: %processed_folders% >> "!REPORT_FILE!"
echo Renamed folders: %renamed_folders% >> "!REPORT_FILE!"
echo Renamed files: %renamed_files% >> "!REPORT_FILE!"
echo Errors: %total_errors% >> "!REPORT_FILE!"
echo. >> "!REPORT_FILE!"
echo Report: %REPORT_FILE% >> "!REPORT_FILE!"

echo.
echo ========================================
echo Processing complete!
echo ========================================
echo [STATS] Processed folders: %processed_folders%
echo [STATS] Renamed folders: %renamed_folders%
echo [STATS] Renamed files: %renamed_files%
echo [STATS] Errors: %total_errors%
echo ========================================
echo [INFO] Report: %REPORT_FILE%
echo [INFO] Report location: %CD%
echo.

pause
    ) else (
        echo [跳过] 文件夹不存在：%%i
        echo [跳过] 文件夹不存在：%%i >> "!REPORT_FILE!"
    )
)

:: 清理临时文件
if exist "!TEMP_CSV!" del "!TEMP_CSV!"
if exist "!MATCHED_CSV!" del "!MATCHED_CSV!"

:: 生成总结报告
echo. >> "!REPORT_FILE!"
echo ======================================== >> "!REPORT_FILE!"
echo 处理总结 >> "!REPORT_FILE!"
echo ======================================== >> "!REPORT_FILE!"
echo 处理的文件夹数：%processed_folders% >> "!REPORT_FILE!"
echo 重命名的文件夹数：%renamed_folders% >> "!REPORT_FILE!"
echo 重命名的文件数：%renamed_files% >> "!REPORT_FILE!"
echo 错误数：%total_errors% >> "!REPORT_FILE!"
echo. >> "!REPORT_FILE!"
echo 报告文件：%REPORT_FILE% >> "!REPORT_FILE!"

echo.
echo ========================================
echo 处理完成！
echo ========================================
echo [统计] 处理的文件夹数：%processed_folders%
echo [统计] 重命名的文件夹数：%renamed_folders%
echo [统计] 重命名的文件数：%renamed_files%
echo [统计] 错误数：%total_errors%
echo ========================================
echo [信息] 报告已生成：%REPORT_FILE%
echo [信息] 报告位置：%CD%
echo.

pause