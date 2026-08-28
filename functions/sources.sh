#!/bin/bash

# SYNOPSIS
# Kupo - Sources management functions
#
# DESCRIPTION
# Provide functions to manage the folders configured as backup sources
#
# NOTES
# Author  : Izunia
# Version : 1.0.0
# License : MIT License



# SYNOPSIS
# Display the folders configured for backup
#
# DESCRIPTION
# Loads the current Moogle conf file and display all configured source folder with a numbered list
# If no folders are configured an message is displayed
#
# EXAMPLE
# Get-Source
#
# OUTPUTS
# None
#
Get-Source() {
    local config

    if ! config=$(Get-Config); then
        Write-Log "No source folders configured" "WARNING"
        Get-String "source.nosources"
        return 1
    fi

    local source_count

    source_count=$(jq '.sources | length' <<< "$config")
    if [[ "$source_count" -eq 0 ]]; then
        Get-String "source.nosources"
    else
        jq -r '.sources[]' <<< "$config" | nl -w 1 -s'. '
    fi

    echo ""
}


# SYNOPSIS
# Adds a folder to the backup sources list
#
# DESCRIPTION
# Prompts the user for a folder path then validates that the path exists
# and adds it to the configured backup sources
# Duplicate paths are not added
#
# EXAMPLE
# Add-Source
#
# OUTPUTS
# None
#
Add-Source() {
    local path
    local resolved_path
    local config
    local new_config

    if ! config=$(Get-Config); then
        Write-Log "Can't have the config file" "ERROR"
        return 1
    fi

    if ! IFS= read -rp "$(Get-String "source.nosources") : " path; then
        path=""
    fi

    if [[ -z "${path//[[:space:]]/}" ]]; then
        Get-String "source.addinvalid"
        Write-Log "Invalid path to the folder to add" "ERROR"
        return 1
    fi

    if [[ ! -d "$path" ]]; then
        Get-String "source.addnotexist"
        Write-Log "Path to the folder does not exist" "ERROR"
        return 1
    fi

    if ! resolved_path="$(cd -- "$path" 2>/dev/null && pwd -P)"; then
        Get-String "source.addnotexist"
        Write-Log "Path to the folder does not exist" "ERROR"
        return 1
    fi

    if jq -e --arg path "$resolved_path" '.sources | index($path)' <<<"$config" >/dev/null; then
        Get-String "source.addduplicate"
        Write-Log "Folder already exists in the list" "WARNING"
        return 1
    fi

    new_config=$(
        jq --arg path "$resolved_path" \
           '.sources += [$path]' <<<"$config"
    )

    if ! Save-Config "$new_config"; then
        Get-String "source.failedsave"
        Write-Log "Failed to save into the config file" "ERROR"
        return 1
    fi

    Get-String "source.addsuccess"
    Write-Log "Folder added successfully" "SUCCESS"
}


# SYNOPSIS
#
#
# DESCRIPTION
# Displays the currently configured backup list and asks the user to select by the number
# The selected folder is removed from the configuration and the updated configuration is saved
# If the selection is invalid nothing is made
#
# EXAMPLE
# Remove-Source
#
# OUTPUTS
# None
#
Delete-Source() {
    local config
    local source_count
    local choice
    local new_config

    if ! config=$(Get-Config); then
        Write-Log "Can't have the config file" "ERROR"
        return 1
    fi

    source_count=$(jq '.sources | length' <<<"$config")

    if [[ "$source_count" -eq 0 ]]; then
        Get-String "source.deletenosources"
        Write-Log "No source folders configured" "WARNING"
        return 1
    fi

    # Display the configured folders and asking for selection
    Get-Source

    if ! IFS= read -rp "$(Get-String "source.deletechoice") : " choice; then
        choice=""
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > source_count )); then
        Get-String "source.deleteinvalid"
        Write-Log "Invalid number for deleting source folder" "ERROR"
        return 1
    fi

    # Rebuild the source list without the selected folder
    new_config=$(jq --argjson index "$((choice - 1))" \
        'del(.sources[$index])' <<< "$config")

    if ! Save-Config "$new_config"; then
        Write-Log "Failed to save into the config file" "ERROR"
        return 1
    fi

    Get-String "source.deletesuccess"
    Write-Log "Source folder removed successfully" "SUCCESS"
}

