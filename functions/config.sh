#!/bin/bash

# SYNOPSIS
# Kupo - Config management functions
#
# DESCRIPTION
# Provide the functions to manage the config file, display it
# and save the modifications
#
# NOTES
# Author  : Izunia
# Version : 1.0.0
# License : MIT License



# SYNOPSIS
# Find the path to the config file
#
# DESCRIPTION
# Load the directory of the config and find the file
#
# EXAMPLE
# Get-Config-Path
#
# OUTPUTS
# echo
#
Get-Config-Path() {
    local script_dir

    script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
    printf '%s/config/config.json\n' "$script_dir"
}


# SYNOPSIS
# Loads the configuration file, creating a default one if needed
#
# DESCRIPTION
# Reads the configuration from config.json
# If the file does not exist a default config is created and saved
#
# EXAMPLE
# Get-Config
#
# OUTPUTS
# echo
# 
Get-Config() {
    local config_file

    config_file=$(Get-Config-Path)

    if [[ ! -f "$config_file" ]]; then
        local default_config

        default_config=$(
            jq -n '{
                backupDrive: {
                    uuid: "",
                    name: "",
                    size: ""
                },
                backupFolder: "Backup",
                sources: [],
                language: "en"
            }'
        )

        mkdir -p "$(dirname "$config_file")" || {
            Write-Log "Failed to create config file" "ERROR"
            return 1
        }

        if ! printf '%s\n' "$default_config" > "$config_file"; then
            Write-Log "Failed to inject default config" "ERROR"
            return 1
        fi

        printf '%s\n' "$default_config"
        return 0
    fi

    if [[ ! -s "$config_file" ]]; then
        Write-Log "Config file is empty" "ERROR"
        Get-String "config.failedload"
        return 1
    fi

    if ! jq empty "$config_file" >/dev/null 2>&1; then
        Write-Log "Config file contains invalid JSON" "ERROR"
        Get-String "config.failedload"
        return 1
    fi

    cat "$config_file"
    Write-Log "Confiiguration file created" "SUCCESS"
    return 0
}


# SYNOPSIS
# Displays the current configuration
# 
# DESCRIPTION
# Loads the config and prints the backup drive, backup folder,
# sources and language settings
#
# EXAMPLE
# Show-Config
#
# OUTPUTS
# echo
# 
Show-Config() {
    local config
    
    if ! config=$(Get-Config); then
        Write-Log "Failed to load configuration" "ERROR"
        Get-String "config.failedload"
        return 1
    fi

    clear

    Write-Log "Showing current configuration" "SUCCESS"
    Get-String "config.currentconfig"

    local uuid name size folder lang
    uuid=$(jq -r '.backupDrive.uuid // ""' <<< "$config")
    name=$(jq -r '.backupDrive.name // ""' <<< "$config")
    size=$(jq -r '.backupDrive.size // ""' <<< "$config")
    folder=$(jq -r '.backupFolder // ""' <<< "$config")
    lang=$(jq -r '.language // ""' <<< "$config")

    Get-String "config.backupdrive"
    if [[ -z "$uuid" ]]; then 
        Get-String "config.nobackupdrive"
    else
        echo "   $(Get-String "config.uuid") : $uuid"
        echo "   $(Get-String "config.name") : $name"
        echo "   $(Get-String "config.size") : $size"
    fi

    echo "$(Get-String "config.folder") : $folder"
    
    Get-String "config.sources"

    local source_count
    source_count=$(jq '.sources | length' <<< "$config")

    if [[ "$source_count" -eq 0 ]]; then
        Get-String "config.nosources"
    else
        jq -r '.sources[]' <<< "$config" | while IFS= read -r src; do
            echo "   $src"
        done
    fi

    echo "$(Get-String "config.lang") : $lang"
}


# SYNOPSIS
# Saves the configuration to the file
#
# DESCRIPTION
# Converts the provided configuration to JSON
# and writes it to config.json (override if needed)
#
# PARAMETER Config
# The configuration object to save
#
# EXAMPLE
# Save-Config $config
#
# OUTPUTS
# None
#
Save-Config() {
    local config="$1"
    local config_file

    config_file=$(Get-Config-Path)

    if [[ -z "${config//[[:space:]]/}" ]]; then
        Write-Log "Config to save is empty" "ERROR"
        Get-String "config.saveerror"
        return 1
    fi

    if ! jq empty <<< "$config" >/dev/null 2>&1; then
        Write-Log "Config to save contains invalid JSON" "ERROR"
        Get-String "config.saveerror"
        return 1
    fi

    if ! mkdir -p "$(dirname "$config_file")"; then
        Write-Log "Failed to create config directory" "ERROR"
        Get-String "config.saveerror"
        return 1
    fi

    if ! jq '.' <<< "$config" > "$config_file"; then
        Write-Log "Failed to write config file" "ERROR"
        Get-String "config.saveerror"
        return 1
    fi

    Write-Log "Config Saved" "SUCCESS"
    Get-String "config.savesuccess"
    return 0
}


