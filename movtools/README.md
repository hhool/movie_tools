# MovTools

A collection of PowerShell scripts for managing media folders and files.

## Scripts

- `extract_movinfo.bat`: Extracts media information from a CSV file based on specified ID ranges.
- `extract_mov_folder_info.bat`: Scans folders and files to extract information into a CSV format.
- `make_name_helper.bat`: A helper script to parse a CSV file and find a matching ID to retrieve the title.
- `move_by_info.ps1`: Moves and renames media files based on information from the media CSV and folder CSV.
- `make_map.ps1`: Generates a mapping file from the media CSV for use in renaming and moving files.

## Usage

### extract movie information at storage location

```cmd
cd root of movtools
.\extract_movinfo.bat  path\to\folder\storage_of_movie
```

generate `extract_mov_folder_info.csv` and `extract_mov_folder_info_summary.csv` in the current directory.

### extract movie info from MediaLibnew.csv

```cmd
cd root of movtools
.\extract_movinfo.bat
```

generate `extract_movinfo.csv` and `extract_movinfo_summary.csv` in the current directory.

### rename and move media files based on info from CSVs


```cmd
set DRYRUN=1
rename_and_move.bat "F:"
```

```cmd
set DRYRUN=0
rename_and_move.bat "F:"
```

This will read `extract_movinfo.csv` and `extract_mov_folder_info.csv` to build a mapping of media IDs to new names, then process the folders listed in `extract_mov_folder_info.csv` to rename and move files accordingly. The `DRYRUN` environment variable controls whether the script actually performs the renaming/moving or just simulates it.