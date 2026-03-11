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
set "SCRIPT_DIR=!SCRIPT_DIR:~0,-1!"
echo [信息] 脚本所在目录：!SCRIPT_DIR!
echo.

:: 检查CSV文件是否在脚本同目录下
set "CSV_FILE=!SCRIPT_DIR!\MediaLibnew.csv"
if not exist "!CSV_FILE!" (
    echo 错误：在脚本目录下未找到 MediaLibnew.csv 文件！
    echo 当前脚本目录：!SCRIPT_DIR!
    echo.
    pause
    exit /b 1
)

echo [信息] 找到CSV文件：!CSV_FILE!
echo.

:: ============ 第一步：遍历文件夹，找出最小和最大值 ============
echo ============ 第1步：扫描文件夹 ============
echo.

set "folder_count=0"
set "min_folder=999999"
set "max_folder=0"
set "num_folder_count=0"
set "non_num_folder_count=0"
set "num_folder_list="
set "non_num_folder_list="

echo [信息] 正在扫描目录：!MEDIA_PATH!
echo ----------------------------------------

for /d %%d in ("!MEDIA_PATH!\*") do (
    set "folder_name=%%~nxd"
    set /a folder_count+=1

    :: 检查是否是纯数字文件夹
    set "is_number=1"
    for /f "delims=0123456789" %%i in ("!folder_name!") do set "is_number=0"

    if "!is_number!"=="1" (
        set /a num_folder_count+=1
        set "num_folder_list=!num_folder_list! !folder_name!"

        :: 将文件夹名转换为数值（去掉前导零）
        set /a "folder_num=!folder_name! + 0"

        :: 更新最小值和最大值
        if !folder_num! lss !min_folder! set "min_folder=!folder_num!"
        if !folder_num! gtr !max_folder! set "max_folder=!folder_num!"

        echo [数字文件夹] 名称:!folder_name! 数值:!folder_num!
    ) else (
        set /a non_num_folder_count+=1
        set "non_num_folder_list=!non_num_folder_list! !folder_name!"
        echo [非数字文件夹] !folder_name! (将被跳过)
    )
)

echo ----------------------------------------
echo.

:: 显示统计信息
echo [统计] 总文件夹数：%folder_count%
echo [统计] 数字文件夹数：%num_folder_count%
echo [统计] 非数字文件夹数：%non_num_folder_count%

if %num_folder_count% equ 0 (
    echo [错误] 未找到任何数字文件夹，无法继续！
    pause
    exit /b 1
)

echo.
echo [范围] 数字文件夹最小值：%min_folder%
echo [范围] 数字文件夹最大值：%max_folder%

:: 计算区间大小
set /a "range_size=!max_folder! - !min_folder! + 1"
echo [范围] 数字文件夹区间：!min_folder! ~ !max_folder! (共 !range_size! 个位置)
echo [范围] 实际存在的文件夹数：!num_folder_count!
set /a "missing_count=!range_size! - !num_folder_count!"
echo [范围] 缺失的文件夹数：!missing_count!

echo.
echo ============ 第2步：读取CSV数据 ============
echo.

:: 读取CSV文件并构建查找表
echo [信息] 正在读取CSV数据库...

:: 临时文件存储CSV数据
set "TEMP_CSV=%temp%\media_data_%random%.tmp"

:: 读取CSV（假设没有标题行，直接读取数据）
set "line_count=0"
set "csv_id_list="
echo [调试] 开始解析CSV文件...
echo.

(for /f "usebackq tokens=1-18 delims=," %%a in ("!CSV_FILE!") do (
    set /a line_count+=1
    set "col1=%%a"      :: 第1列：ID
    set "col2=%%b"      :: 第2列：豆瓣ID
    set "col3=%%c"      :: 第3列：影片名
    set "col4=%%d"      :: 第4列：类型
    set "col5=%%e"      :: 第5列：宽度
    set "col6=%%f"      :: 第6列：高度
    set "col7=%%g"      :: 第7列：大小
    set "col8=%%h"      :: 第8列：编码
    set "col9=%%i"      :: 第9列：音频1
    set "col10=%%j"     :: 第10列：音频2
    set "col11=%%k"     :: 第11列：原片名
    set "col12=%%l"     :: 第12列：日期
    set "col13=%%m"     :: 第13列：导演
    set "col14=%%n"     :: 第14列：时长
    set "col15=%%o"     :: 第15列：国家
    set "col16=%%p"     :: 第16列：图片
    set "col17=%%q"     :: 第17列：未知
    set "col18=%%r"     :: 第18列：路径

    :: 清理可能的引号和空格
    set "col1=!col1:"=!"
    set "col3=!col3:"=!"
    set "col11=!col11:"=!"
    set "col15=!col15:"=!"
    set "col16=!col16:"=!"

    :: 去除首尾空格
    for /f "tokens=* delims= " %%i in ("!col1!") do set "col1=%%i"
    for /f "tokens=* delims= " %%i in ("!col3!") do set "col3=%%i"
    for /f "tokens=* delims= " %%i in ("!col11!") do set "col11=%%i"
    for /f "tokens=* delims= " %%i in ("!col15!") do set "col15=%%i"
    for /f "tokens=* delims= " %%i in ("!col16!") do set "col16=%%i"

    :: 将CSV第一列转换为数值
    set /a "csv_num=!col1! + 0"

    :: 处理影片名：如果第3列为空，使用第11列（原片名）
    if "!col3!"=="" (
        set "movie_name=!col11!"
    ) else (
        set "movie_name=!col3!"
    )

    if "!movie_name!"=="" set "movie_name=未知"

    :: 国家字段：第15列应该是国家
    set "country=!col15!"

    :: 验证国家字段是否为有效国家（不是URL）
    echo !country! | findstr /i "http://" >nul && set "country=未知"
    echo !country! | findstr /i "https://" >nul && set "country=未知"
    echo !country! | findstr /i "www." >nul && set "country=未知"
    echo !country! | findstr /i ".jpg" >nul && set "country=未知"
    echo !country! | findstr /i ".png" >nul && set "country=未知"
    echo !country! | findstr /i ".gif" >nul && set "country=未知"
    echo !country! | findstr /i ".bmp" >nul && set "country=未知"

    if "!country!"=="" set "country=未知"

    :: 每10行显示一个进度
    set /a "mod=!line_count! %% 10"
    if !mod! equ 0 (
        echo [进度] 已读取 !line_count! 行...
    )

    :: 调试信息（显示前50行）
    if !line_count! leq 50 (
        echo [调试] 第!line_count!行: ID=!col1!, 影片名="!movie_name!", 国家="!country!"
    )

    :: 保存到临时文件：数值ID|原始ID|影片名|国家
    echo !csv_num!^|!col1!^|!movie_name!^|!country!>> "!TEMP_CSV!"
    set "csv_id_list=!csv_id_list! !csv_num!"
)) 2>nul

echo.
echo [信息] CSV共读取 %line_count% 行数据
echo.

:: 显示CSV中的ID范围
if !line_count! gtr 0 (
    set "csv_min=999999"
    set "csv_max=0"
    for %%i in (%csv_id_list%) do (
        if %%i lss !csv_min! set "csv_min=%%i"
        if %%i gtr !csv_max! set "csv_max=%%i"
    )
    echo [CSV统计] CSV中的数值ID范围：!csv_min! ~ !csv_max!
    echo [CSV统计] CSV中的ID数量：%line_count%
)

echo.
echo ============ 第3步：按区间匹配CSV数据 ============
echo.

:: 根据最小值到最大值区间读取CSV
echo [信息] 根据文件夹区间 !min_folder! ~ !max_folder! 匹配CSV数据...
echo.

set "matched_count=0"
set "unmatched_count=0"
set "expected_count=!range_size!"

echo [匹配] 期望匹配的行数：!expected_count! (!min_folder! 到 !max_folder! 共 !range_size! 个数字)
echo [匹配] CSV实际行数：%line_count%
echo.

:: 创建新的匹配文件
set "MATCHED_CSV=%temp%\matched_data_%random%.tmp"
if exist "!MATCHED_CSV!" del "!MATCHED_CSV!"

:: 按顺序读取CSV并匹配
echo [信息] 按顺序匹配CSV数据：
echo ----------------------------------------

for /l %%i in (!min_folder!,1,!max_folder!) do (
    set "found=0"
    set "original_id="
    set "movie="
    set "country="

    for /f "tokens=1-4 delims=|" %%a in ('type "!TEMP_CSV!" 2^>nul') do (
        if %%i equ %%a (
            set "found=1"
            set "original_id=%%b"
            set "movie=%%c"
            set "country=%%d"
            echo [匹配成功] 数值ID:%%i - 原始ID:%%b - 影片:%%c - 国家:%%d
            echo %%i^|%%b^|%%c^|%%d>> "!MATCHED_CSV!"
            set /a matched_count+=1
        )
    )

    if !found! equ 0 (
        echo [匹配失败] 数值ID:%%i - CSV中无对应数据 (将使用"未知")
        echo %%i^|%%i^|未知^|未知>> "!MATCHED_CSV!"
        set /a unmatched_count+=1
    )
)

echo ----------------------------------------
echo.

echo [结果] 匹配成功：!matched_count! 行
echo [结果] 匹配失败：!unmatched_count! 行
echo [结果] 匹配文件已生成：!MATCHED_CSV!

:: 显示匹配文件内容预览
echo.
echo [预览] 匹配文件前20行：
if exist "!MATCHED_CSV!" (
    type "!MATCHED_CSV!" | findstr /n . | findstr /b "[1-20]:"
) else (
    echo [错误] 匹配文件未生成！
    pause
    exit /b 1
)
echo.

:: 询问用户是否继续
echo.
echo [提示] 发现有 !unmatched_count! 个ID在CSV中无对应数据
echo [提示] 这些文件夹将被命名为"未知+未知"
echo.
set /p "confirm=是否开始处理以上匹配的文件夹？(Y/N): "
if /i not "!confirm!"=="Y" (
    echo 用户取消操作
    if exist "!TEMP_CSV!" del "!TEMP_CSV!"
    if exist "!MATCHED_CSV!" del "!MATCHED_CSV!"
    pause
    exit /b 0
)
echo.

:: ============ 第四步：开始处理（使用+号连接） ============
echo ============ 第4步：开始处理文件夹 ============
echo.

:: 初始化报告
echo ======================================== > "!REPORT_FILE!"
echo    %SCRIPT_NAME% 处理报告 >> "!REPORT_FILE!"
echo ======================================== >> "!REPORT_FILE!"
echo 处理时间：%date% %time% >> "!REPORT_FILE!"
echo 媒体库路径：!MEDIA_PATH! >> "!REPORT_FILE!"
echo CSV文件：!CSV_FILE! >> "!REPORT_FILE!"
echo. >> "!REPORT_FILE!"
echo [扫描结果] 总文件夹数：%folder_count% >> "!REPORT_FILE!"
echo [扫描结果] 数字文件夹数：%num_folder_count% >> "!REPORT_FILE!"
echo [扫描结果] 数字文件夹范围：%min_folder% ~ %max_folder% >> "!REPORT_FILE!"
echo [扫描结果] 区间大小：!range_size! >> "!REPORT_FILE!"
echo [扫描结果] CSV数据行数：%line_count% >> "!REPORT_FILE!"
echo [匹配结果] 匹配成功：!matched_count! 行 >> "!REPORT_FILE!"
echo [匹配结果] 匹配失败：!unmatched_count! 行 >> "!REPORT_FILE!"
echo. >> "!REPORT_FILE!"

:: 处理每个数字文件夹
set "processed_folders=0"
set "renamed_folders=0"
set "renamed_files=0"
set "total_errors=0"

echo [信息] 开始遍历区间 !min_folder! 到 !max_folder! ...
echo.

for /l %%i in (!min_folder!,1,!max_folder!) do (
    set "folder_path=!MEDIA_PATH!\%%i"

    if exist "!folder_path!\" (
        echo [处理] 正在处理文件夹：%%i
        echo [处理] 文件夹路径：!folder_path!

        :: 在匹配文件中查找对应数据
        set "found=0"
        for /f "tokens=1-4 delims=|" %%a in ('type "!MATCHED_CSV!" 2^>nul') do (
            if %%i equ %%a (
                set "found=1"
                set "original_id=%%b"
                set "movie_name=%%c"
                set "country=%%d"

                if "!movie_name!"=="未知" (
                    echo   [警告] CSV中无影片数据，将使用"未知"
                )

                if "!country!"=="未知" (
                    echo   [警告] CSV中无国家数据，将使用"未知"
                )

                :: 新文件夹名：影片名+国家（使用+号连接）
                set "new_folder_name=!movie_name!+!country!"

                echo   [信息] 新文件夹名: !new_folder_name!

                :: 处理文件夹内的文件
                set "file_count=0"

                :: 处理001文件（无扩展名的视频文件）
                if exist "!folder_path!\001" (
                    set "new_file_name=!new_folder_name!.mp4"
                    echo   [处理] 重命名视频文件: 001 -^> !new_file_name!

                    ren "!folder_path!\001" "!new_file_name!" 2>nul
                    if !errorlevel! equ 0 (
                        echo   [成功] 视频文件重命名成功
                        echo   [成功] 视频文件重命名: 001 -^> !new_file_name! >> "!REPORT_FILE!"
                        set /a file_count+=1
                        set /a renamed_files+=1
                    ) else (
                        echo   [失败] 视频文件重命名失败，错误码：!errorlevel!
                        echo   [失败] 视频文件重命名: 001 >> "!REPORT_FILE!"
                        set /a total_errors+=1
                    )
                ) else (
                    echo   [信息] 未找到001视频文件
                )

                :: 处理001.srt字幕文件
                if exist "!folder_path!\001.srt" (
                    set "new_sub_name=!new_folder_name!.srt"
                    echo   [处理] 重命名字幕文件: 001.srt -^> !new_sub_name!

                    ren "!folder_path!\001.srt" "!new_sub_name!" 2>nul
                    if !errorlevel! equ 0 (
                        echo   [成功] 字幕文件重命名成功
                        echo   [成功] 字幕文件重命名: 001.srt -^> !new_sub_name! >> "!REPORT_FILE!"
                        set /a file_count+=1
                        set /a renamed_files+=1
                    ) else (
                        echo   [失败] 字幕文件重命名失败，错误码：!errorlevel!
                        echo   [失败] 字幕文件重命名: 001.srt >> "!REPORT_FILE!"
                        set /a total_errors+=1
                    )
                ) else (
                    echo   [信息] 未找到001.srt字幕文件
                )

                :: 重命名文件夹
                if not "%%i"=="!new_folder_name!" (
                    echo   [处理] 重命名文件夹: %%i -^> !new_folder_name!

                    ren "!folder_path!" "!new_folder_name!" 2>nul
                    if !errorlevel! equ 0 (
                        echo   [成功] 文件夹重命名成功
                        echo   [成功] 文件夹重命名: %%i -^> !new_folder_name! >> "!REPORT_FILE!"
                        set /a renamed_folders+=1
                    ) else (
                        echo   [失败] 文件夹重命名失败，错误码：!errorlevel!
                        echo   [失败] 文件夹重命名: %%i >> "!REPORT_FILE!"
                        set /a total_errors+=1
                    )
                ) else (
                    echo   [信息] 文件夹名无需更改
                )

                set /a processed_folders+=1
            )
        )
        echo.
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