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
    echo "Source not found : $source"
    return 1
    fi
    
    if [[ ! -d "$destination" ]]; then
    mkdir -p "$destination"
    fi
    
    local source_name
    source_name=$(basename "$source")
    
    local archive_path="$destination/$source_name.zip"
    
    echo "Compressing : $source_name"
    
    local source_parent
    source_parent=$(dirname "$source")
    
    if ! (
    cd "$source_parent" || exit 1
    zip -r -q "$archive_path" "$source_name"
        ); then
    echo "Failed to compress : $source"
    return 1
    fi
    
    echo "Compression completed : $source_name.zip"
    
    printf '%s\n' "$archive_path"
}
 
Compress-Backup() {
    local destination="$1"
    
    shift
    
    local sources=("$@")
    
    local total=${#sources[@]}
    local current=0
    
    if (( total == 0 )); then
    echo "No sources to compress"
    return 1
    fi
    
    for source in "${sources[@]}"
    do
    ((current++))
    
    local source_name
    source_name=$(basename "$source")
    
    echo "[$current/$total] Compressing : $source_name"
    Show-ProgressBar "$current" "$total" "Compressing" "$source_name ($current/$total)"
    
    if ! Compress-Source "$source" "$destination" > /dev/null; then
    echo
    echo "Backup compression failed"
    return 1
    fi
    done
    
    echo
    echo "All sources compressed"
    
    return 0
}
 
Compress-BackupFolder() {
    local source_folder="$1"
    local destination="$2"
    local archive_name="$3"
    
    if [[ ! -d "$source_folder" ]]; then
    echo "Source folder not found : $source_folder" >&2
    return 1
    fi
    
    if [[ ! -d "$destination" ]]; then
    mkdir -p "$destination"
    fi
    
    local archive_path="$destination/$archive_name.zip"
    
    echo "Creating final backup archive..." >&2
    
    if ! (
    cd "$source_folder" || exit 1
    zip -r -q "$archive_path" ./*
        ); then
    echo "Failed to create final backup archive" >&2
    return 1
    fi
    
    echo "Final compression completed : $archive_name.zip" >&2
    
    printf '%s\n' "$archive_path"
}


