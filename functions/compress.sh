#!/bin/bash

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
    
    if [[ -d "$source" ]]; then
        zip -r -q "$archive_path" "$source"
    else
        zip -q "$archive_path" "$source"
    fi

    if [[ $? -ne 0 ]]; then
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
        source_name=$(basenmae "$source")

        echo "[$current/$total] Compressing : $source_name"

        if ! Compress-Source "$source" "$destination"; then
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
        echo "Source folder not found : $source_folder"
        return 1
    fi

    if [[ ! -d "$destination" ]]; then
        mkdir -p "$destination"
    fi

    local archive_path="$destination/$archive_name.zip"

    echo "Creating final backup archive..."

    (
        cd "$source_folder" || exit 1
        zip -r -q "$archive_path" ./*
    )

    if [[ $? -ne 0 ]]; then
        echo "Failed to create final backup"
        return 1
    fi

    echo "Final compression completed : $archive_name.zip"

    printf '%s\n' "$archive_path"
}