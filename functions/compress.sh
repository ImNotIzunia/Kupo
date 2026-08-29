#!/bin/bash

# SYNOPSIS
# Kupo - Compress management functions
#
# DESCRIPTION
# Provide functions to compress the sources into archives
#
# NOTES
# Author  : Izunia
# Version : 1.0.0
# License : MIT License



# SYNOPSIS
# Compresses a single backup source into a zip archive
#
# DESCRIPTION
# Validates that the source exists creates the destination folder if needed
# then compresses the source into a zip archive named after the source
#
# PARAMETER Source
# The path of the file or folder to compress
#
# PARAMETER Destination
# The folder where the resulting archive will be created
#
# EXAMPLE
# Compress-Source "/Documents/" "/Kupo/Temp"
#
# OUTPUTS
# printf
#
Compress-Source() {
    local source="$1"
    local destination="$2"
    
    if [[ ! -e "$source" ]]; then
    Write-Log "Source not found : $source" "ERROR"
    Get-String "compress.nosource"
    return 1
    fi
    
    if [[ ! -d "$destination" ]]; then
    mkdir -p "$destination"
    fi
    
    local source_name
    source_name=$(basename "$source")
    
    local archive_path="$destination/$source_name.zip"
    
    echo "$(Get-String "compress.compress") : $source_name"
    Write-Log "Compressing : $source_name" "INFO"
    
    local source_parent
    source_parent=$(dirname "$source")
    
    if ! (
    cd "$source_parent" || exit 1
    zip -r -q "$archive_path" "$source_name"
        ); then
    echo "$(Get-String "compress.failed") : $source"
    Write-Log "Failed to compress : $source" "ERROR"
    return 1
    fi
    
    echo "$(Get-String "compress.sucess") : $source_name.zip"
    Write-Log "Compression completed : $source_name.zip" "SUCCESS"
    
    printf '%s\n' "$archive_path"
}


# SYNOPSIS
# Compresses all configured backup sources
#
# DESCRIPTION
# Iterates over the list of sources and compresses each one individually
# into the destination folder
# The process stops if any source fails to compress
#
# PARAMETER Destination
# The folder where the resulting archives will be created
#
# EXAMPLE
# Compress-Backup "/Kupo/temp"
#
# OUTPUTS
# echo
#
Compress-Backup() {
    local destination="$1"
    
    shift
    
    local sources=("$@")
    
    local total=${#sources[@]}
    local current=0
    
    if (( total == 0 )); then
        return 1
    fi
    
    for source in "${sources[@]}"; do
        ((current++))
        
        local source_name
        source_name=$(basename "$source")
        
        echo "[$current/$total] Compressing : $source_name"
        Show-ProgressBar "$current" "$total" "Compressing" "$source_name ($current/$total)"
        
        if ! Compress-Source "$source" "$destination" > /dev/null; then
            echo
            Get-String "compress.backupfailed"
            Write-Log "Backup Compression Failed" "ERROR"
            return 1
        fi
    done
    
    echo
    Get-String "compress.backupsucess"
    Write-Log "Backup Compression Success" "SUCCESS"
    
    return 0
}


# SYNOPSIS
# Compresses a folder of archives into a single final backup archive
#
# DESCRIPTION
# Compresses the entire content of the given source folder into
# a single ZIP file after the current backup placed in the destination folder
#
# PARAMETER Source_folder
# The folder whose content will be compressed into the final archive
#
# PARAMETER Destination
# The folder where the resulting final archive will be created
# Must be different from SourceFolder to avoid the archive including itself
#
# PARAMETER Archive_name
# The name (without extension) to give the final archive
#
# EXAMPLE
# Compress-BackupFolder "/kupo/temp/save" "/kupo/temp" "backup" 
Compress-BackupFolder() {
    local source_folder="$1"
    local destination="$2"
    local archive_name="$3"
    
    if [[ ! -d "$source_folder" ]]; then
        Write-Log "Source folder not found : $source_folder" "ERROR"
        echo "$(Get-String "compress.foldernotfound") : $source_folder"
        return 1
    fi
    
    if [[ ! -d "$destination" ]]; then
        mkdir -p "$destination"
    fi
    
    local archive_path="$destination/$archive_name.zip"
    
    Get-String "compress.foldercreate"
    Write-Log "Creating final backup archive..." "INFO"
    
    if ! (
        cd "$source_folder" || exit 1
        zip -r -q "$archive_path" ./*
            ); then

        Get-String "compress.folderfailed"
        Write-Log "Failed to create final backup archive" "ERROR"
        return 1
    fi
    
    echo "$(Get-String "compress.foldersuccess") : $archive_name.zip"
    Write-Log "Final compression completed : $archive_name.zip" "SUCCESS"
    
    printf '%s\n' "$archive_path"
}


