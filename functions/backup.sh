#!/bin/bash

# SYNOPSIS
# Kupo - Backup management functions
#
# DESCRIPTION
# Provide functions to validate the config file, build backup paths,
# manage temp folder and start backup process
#
# NOTES
# Author  : Izunia
# Version : 1.0.0
# License : MIT License



# SYNOPSIS
# Validates the current configuration
#
# DESCRIPTION
#
# Checks whether the configuration can be loaded and verifies that
# a backup drive, backup folder and at least one backup source are configured
#
# Returns the loaded configuration when all checks pass
#
# EXAMPLE
# Test-Config
#
# OUTPUTS
# echo
#
Test-Config() {
    local config

    if ! config=$(Get-Config); then
        Write-Log "Failed to load configuration" "ERROR"
        return 1
    fi

    local uuid
    local backup_folder
    local source_count

    uuid=$(jq -r '.backupDrive.uuid // ""' <<< "$config")
    backup_folder=$(jq -r '.backupFolder // ""' <<< "$config")
    source_count=$(jq '.sources | length' <<< "$config")

    if [[ -z "$uuid" ]]; then
        Get-String "backup.nobackupdrive"
        Write-Log "No backup drive configured" "ERROR"
        return 1
    fi

    if [[ -z "$backup_folder" ]]; then
    Get-String "backup.nobackupfolder"
        Write-Log "No backup folder configured" "ERROR"
    return 1
    fi

    local mountpoint
    mountpoint=$(findmnt -rn -S "UUID=$uuid" -o TARGET)

    if [[ -z "$mountpoint" ]]; then
        Get-String "backup.notconnected"
        Write-Log "Backup drive is not connected" "ERROR"
        return 1
    fi

    if (( source_count == 0 )); then
        Get-String "backup.nosources"
        Write-Log "No sources configured" "ERROR"
        return 1
    fi

    while IFS= read -r source
    do
        if [[ ! -e "$source" ]]; then
            echo "$(Get-String "backup.notfound") : $source"
            Write-Log "Source not found : $source" "ERROR"
            return 1
        fi
    done < <(jq -r '.sources[]' <<< "$config")

    printf '%s\n' "$config"
}


# SYNOPSIS
# Builds the destination path for the current backup
#
# DESCRIPTION
# Creates a backup path using the configured backup drive and folder
# The path is organized by year, month, day
#
# PARAMETER Config
# The configuration file containing the backup drive and folder
#
# EXAMPLE
# Get-BackupPath $config
#
# OUTPUTS
# echo
#
Get-BackupPath() {
    local config="$1"

    local uuid
    local backup_folder
    local mountpoint

    uuid=$(jq -r '.backupDrive.uuid' <<< "$config")
    backup_folder=$(jq -r '.backupFolder' <<< "$config")

    mountpoint=$(findmnt -rn -S "UUID=$uuid" -o TARGET)

    if [[ -z "$mountpoint" ]]; then
        Get-String "backup.notmounted"
        Write-Log "Backup drive not connected" "ERROR"
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


# SYNOPSIS
# Create the backup destination directory
#
# DESCRIPTION
# Creates the specified backup directory if it does not already exist
# If the directory already exist no changes are made
#
# PARAMETER Path
# The path of the backup directory to create
#
# EXAMPLE
# Set-BackupPath "D:\Backup\2026\08\Backup_2026_08_29"
#
# OUTPUTS
# None
#
Set-BackupPath() {
    local path="$1"

    if [[ ! -d "$path" ]]; then

        if ! mkdir -p "$path"; then
            echo "$(Get-String "backup.failedcreate") : $path"
            Write-Log "Failed to create backup path : $path" "ERROR"
            return 1
        fi

        echo "$(Get-String "backup.createbackup") : $path"
        Write-Log "Created backup path : $path" "SUCCESS"

    else
        echo "$(Get-String "backup.alreadycreate") : $path"
        Write-Log "Backup path already exists: $path" "ERROR"
    fi
}


# SYNOPSIS
# Creates a temporary directory for the backup process
#
# DESCRIPTION
# Removes any existing temporary folder and creates a new one
# The resolved path of the temp folder is returned
#
# EXAMPLE
# Set-TempFolder
#
# OUTPUTS
# None
#
Set-TempFolder() {
    local script_dir
    script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

    local temp_path="$script_dir/temp"

    if [[ -d "$temp_path" ]]; then
        rm -rf "$temp_path"
    fi

    if ! mkdir -p "$temp_path"; then
        Get-String "backup.failedtemp"
        Write-Log "Failed to create temp folder" "ERROR"
        return 1
    fi
}


# SYNOPSIS
# Starts the backup process
#
# DESCRIPTION
# Validates the configuration, creates a temp folder and the backup destination,
# compresses the sources copies the archives and cleans the temp files
#
# The backup process stops if configuration validation, compression
# or file copying fails
#
# EXAMPLE
# Start-Backup
#
# OUTPUTS
# None
#
Start-Backup() {
    Write-Log "Starting Backup" "INFO"
    Get-String "backup.startbackup"
    echo

    local config

    if ! config=$(Test-Config); then
        return 1
    fi

    local temp_path

    temp_path=$(Set-TempFolder)

    if [[ -z "$temp_path" ]]; then
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

    Write-Log "Backup Destination : $backup_path.zip" "INFO"
    Get-String "backup.destination"
    echo "  $backup_path.zip"
    echo

    mapfile -t sources < <(
        jq -r '.sources[]' <<< "$config"
    )

    if ! Compress-Backup "$temp_path" "${sources[@]}"; then
        Write-Log "Backup failed during compression" "ERROR"
        Get-String "backup.failedcompression"
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
        Write-Log "Backup failed during final compression" "ERROR"
        Get-String "backup.failedfinalcompression"
        rm -rf "$temp_path"
        return 1
    fi

    echo
    Write-Log "Copying Backup" "INFO"
    Get-String "backup.copy"
    echo

    if ! cp "$final_archive" "$backup_parent/"; then
        Write-Log "Backup failed during copy" "ERROR"
        Get-String "backup.failedcopy"
        rm -rf "$temp_path"
        rm -f "$final_archive"
        return 1
    fi

    rm -rf "$temp_path"
    rm -f "$final_archive"

    echo
    Write-Log "Backup Completed" "SUCCESS"
    Get-String "backup.completed"
    echo
}



