#!/bin/bash

Test-Config() {
    local config

    if ! config=$(Get-Config); then
        echo "Failed to load configuration"
        return 1
    fi

    local uuid
    local backup_folder
    local source_count

    uuid=$(jq -r '.backupDrive.uuid // ""' <<< "$config")
    backup_folder=$(jq -r '.backupFolder // ""' <<< "$config")
    source_count=$(jq '.sources | length' <<< "$config")

    if [[ -z "$uuid" ]]; then
        echo "No back drive configured"
        return 1
    fi

    if [[ -z "$backup_folder" ]]; then
    echo "No backup folder configured"
    return 1
    fi

    local mountpoint
    mountpoint=$(findmnt -rn -S "UUID=$uuid" -o TARGET)

    if [[ -z "$mountpoint" ]]; then
        echo "Backup drive is not connected"
        return 1
    fi

    if (( source_count == 0 )); then
        echo "No sources configured"
        return 1
    fi

    while IFS= read -r source
    do
        if [[ ! -e "$source" ]]; then
            echo "Source not found : $source"
            return 1
        fi
    done < <(jq -r '.sources[]' <<< "$config")

    printf '%s\n' "$config"
}


Get-BackupPath() {
    local config="$1"

    local uuid
    local backup_folder
    local mountpoint

    uuid=$(jq -r '.backupDrive.uuid' <<< "$config")
    backup_folder=$(jq -r '.backupFolder' <<< "$config")

    mountpoint=$(findmnt -rn -S "UUID=$uuid" -o TARGET)

    if [[ -z "$mountpoint" ]]; then
        echo "Backup drive is not mounted"
        return 1
    fi

    local year
    local month
    local backup_name

    year=$(date '+%Y')
    month=$(date '+%m')
    backup_name="Backup_$(date '+%Y_%m_%d')"

    printf '%s\n' \
        "$mountpoint/$backup_folder/$year/$month/$backup_name"
}


Set-BackupPath() {
    local path="$1"

    if [[ ! -d "$path" ]]; then

        if ! mkdir -p "$path"; then
            echo "Failed to create backup path : $path"
            return 1
        fi

        echo "Created backup path : $path"

    else

        echo "Backup path already exists : $path"

    fi
}


Set-TempFolder() {
    local script_dir
    script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

    local temp_path="$script_dir/temp"

    if [[ -d "$temp_path" ]]; then
        rm -rf "$temp_path"
    fi

    if ! mkdir -p "$temp_path"; then
        echo "Failed to create temporary folder" >&2
        return 1
    fi

    printf '%s\n' "$temp_path"
}


Start-Backup() {
    echo
    echo "Starting backup..."
    echo

    local config

    if ! config=$(Test-Config); then
        echo
        echo "Backup cancelled."
        return 1
    fi

    local temp_path

    temp_path=$(Set-TempFolder)

    if [[ -z "$temp_path" ]]; then
        echo "Failed to create temporary folder"
        return 1
    fi

    local backup_path

    if ! backup_path=$(Get-BackupPath "$config"); then
        return 1
    fi

    local backup_parent
    local backup_name

    backup_parent=$(dirname "$backup_path")
    backup_name=$(basename "$backup_path")

    if ! Set-BackupPath "$backup_parent"; then
        return 1
    fi

    echo
    echo "Backup destination :"
    echo "  $backup_path.zip"
    echo

    mapfile -t sources < <(
        jq -r '.sources[]' <<< "$config"
    )

    if ! Compress-Backup "$temp_path" "${sources[@]}"; then
        echo "Backup failed during compression"
        rm -rf "$temp_path"
        return 1
    fi

    local final_archive

    final_archive=$(Compress-BackupFolder \
        "$temp_path" \
        "$(dirname "$temp_path")" \
        "$backup_name"
    )

    if [[ -z "$final_archive" || ! -f "$final_archive" ]]; then
        echo "Backup failed during final compression"
        rm -rf "$temp_path"
        return 1
    fi

    echo
    echo "Copying backup..."
    echo

    if ! cp "$final_archive" "$backup_parent/"; then
        echo "Backup failed during copy"
        rm -rf "$temp_path"
        rm -f "$final_archive"
        return 1
    fi

    rm -rf "$temp_path"
    rm -f "$final_archive"

    echo
    echo "Backup completed successfully."
    echo
}




