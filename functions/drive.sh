#!/bin/bash

# SYNOPSIS
# Kupo - Backup drive management functions
#
# DESCRIPTION
# Provide the functions to manage external drives for the backup folder
#
# NOTES
# Author  : Izunia
# Version : 1.0.0
# License : MIT License



# SYNOPSIS
# Formats a storage size into readable string
#
# DESCRIPTION
# Converts a size expressed in gigabytes into a rounded string
# Values of 1000Gb or more are converted to Terabytes
#
# PARAMETER Size
# The size in gigabytes to format
#
# EXAMPLE
# Format-StorageSize 512
#
# OUTPUTS
# echo
#
Format-StorageSize() {
    local size="$1"

    if (( $(echo "$size >= 1000" | bc -l) )); then
        printf "%.1fTo\n" "$(echo "$size / 1000" | bc -l)"
    else
        printf "%sGo\n" "$(echo "($size+0.5)/1" | bc)"
    fi
}


# SYNOPSIS
# Retrieves the list of external drives connected to the computer
#
# DESCRIPTION
# Queries disks connected to the computer and returns them
# along with their letter, name, total size and free space percentage
#
# EXAMPLE
# Get-ExternalDrives
#
# OUTPUTS
# echo
#
Get-ExternalDrives() {
    lsblk -nr -o NAME,TYPE,SIZE,LABEL,UUID,MOUNTPOINTS |
        awk '$2 == "part" && $6 != "" {
            print $1 "|" $3 "|" $4 "|" $5 "|" $6
        }'
}


# SYNOPSIS
# Displays the currently configured backup drive
#
# DESCRIPTION
# Loads the config file and prints the letter and 
# name of the configured backup drive
#
# EXAMPLE
# Show-BackupDrive
#
# OUTPUTS
# None
#
Show-BackupDrive() {
    local config

    if ! config=$(Get-Config); then
        Get-String "drive.configfailed"
        Write-Log "Failed to load configuration" "ERROR"
        return 1
    fi

    uuid=$(jq -r '.backupDrive.uuid // ""' <<< "$config")
    name=$(jq -r '.backupDrive.name // ""' <<< "$config")
    size=$(jq -r '.backupDrive.size // ""' <<< "$config")

    if [[ -z "$uuid" ]]; then
        Get-String "drive.nodrive"
        Write-Log "No Backup Drive configured" "WARNING"
        return 0
    fi

    Get-String "drive.actual"
    echo "  $(Get-String "drive.drivename") : $name"
    echo "  $(Get-String "drive.driveuuid") : $uuid"
    echo "  $(Get-String "drive.drivesize") : $size"
}


# SYNOPSIS
# Sets the backup drive from the list of available external drives
#
# DESCRIPTION
# Lists the connected drives and prompts the user to choose one
# The selected drive's letter, name and size are saved into the config file
#
# EXAMPLE
# Set-BackupDrive
#
# OUTPUTS
# None
#
Set-BackupDrive() {
    local config

    if ! config=$(Get-Config); then
        Get-String "drive.configfailed"
        Write-Log "Failed to load configuration" "ERROR"
        return 1
    fi

    mapfile -t drives < <(Get-ExternalDrives)

    if [[ ${#drives[@]} -eq 0 ]]; then
        Get-String "drive.notfound"
        Write-Log "No storage drive founded" "WARNING"
        return 0
    fi

    Get-String "drive.founddrive"
    Write-Log "Showing available drives" "INFO"
    echo

    for i in "${!drives[@]}"
    do
        IFS="|" read -r name size label uuid mountpoint <<< "${drives[$i]}"

        printf "%d - %s (%s - %s)\n" \
            "$((i + 1))" \
            "${label:-Sans nom}" \
            "$size" \
            "$mountpoint"
    done

    echo

    read -rp "$(Get-String "drive.choice") : " choice

    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        Get-String "drive.invalidchoice"
        Write-Log "Invalid number for selecting backup drive" "ERROR"
        return 1
    fi

    local index=$((choice - 1))

    if (( index < 0 || index >= ${#drives[@]} )); then
        Get-String "drive.invalidchoice"
        Write-Log "Invalid number for selecting backup drive" "ERROR"
        return 1
    fi

    IFS="|" read -r name size label uuid mountpoint <<< "${drives[$index]}"

    if [[ -z "$uuid" ]]; then
        Get-String "drive.cantuuid"
        Write-Log "Can't retrive the UUID" "ERROR"
        return 1
    fi

    echo "$(Get-String "drive.driveselected") : ${label:-Sans nom}"
    echo "  $(Get-String "drive.driveuuid") : $uuid"
    echo "  $(Get-String "drive.drivetaille") : $size"
    echo "  $(Get-String "drive.drivemounted") : $mountpoint"

    if ! config=$(
        jq \
            --arg uuid "$uuid" \
            --arg name "${label:-Sans nom}" \
            --arg size "$size" \
            '
            .backupDrive.uuid = $uuid |
            .backupDrive.name = $name |
            .backupDrive.size = $size
            ' <<< "$config"
    ); then
        Write-Log "Error during update" "ERROR"
        return 1
    fi

    if ! Save-Config "$config"; then
        Get-String "drive.savefailed"
        Write-Log "Failed to save configuration" "ERROR"
        return 1
    fi

    Get-String "drive.drivesuccess"
    Write-Log "Backup Drive added successfully" "SUCCESS"
}


# SYNOPSIS
# Sets the backup folder name
# 
# DESCRIPTION
# Displays the current backup folder and prompts the user for a new one
# If the input is empty, the current folde name is kept unchanged
#
# EXAMPLE
# Set-BackupFolder
#
# OUTPUTS
# None
#
Set-BackupFolder() {
    local config

    if ! config=$(Get-Config); then
        Get-String "drive.configfailed"
        Write-Log "Failed to load configuration" "ERROR"
        return 1
    fi

    local current_folder
    current_folder=$(jq -r '.backupFolder // ""' <<< "$config")

    echo "$(Get-String "drive.currentfolder") : $current_folder"
    Write-Log "Current backup folder : $current_folder" "INFO"
    echo

    read -rp "$(Get-String "drive.folderchoice") : " folder

    if [[ -z "$folder" ]]; then
        folder="$current_folder"
    fi

    if ! config=$(
        jq \
            --arg folder "$folder" \
            '.backupFolder = $folder' \
            <<< "$config"
    ); then
        Write-Log "Error during update" "ERROR"
        return 1
    fi

    if ! Save-Config "$config"; then
        Get-String "drive.savefailed"
        Write-Log "Failed to save configuration" "ERROR"
        return 1
    fi

    Get-String "drive.folderchange"
    Write-Log "Backup folder updated successfully : $folder" "SUCCESS"
}

