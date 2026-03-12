# run_all.bat

拖动文件夹到这个批处理文件上，或者在命令行中指定文件夹路径作为参数：

```cmd
run_all.bat "path\to\folder\storage_of_movie"
```

执行完毕后会在当前目录下生成 `extract_mov_folder_info.csv`、`extract_mov_folder_info_summary.csv`、`extract_movinfo.csv` 和 `extract_movinfo_summary.csv` 四个文件。然后你可以根据需要设置 `DRYRUN` 环境变量来执行重命名和移动操作：

```cmd
set DRYRUN=1
run_all.bat "path\to\folder\storage_of_movie"
```

```cmd
set DRYRUN=0
run_all.bat "path\to\folder\storage_of_movie"
```