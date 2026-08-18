#!/bin/bash

Get-Config() {
    CONFIG_FILE="$(dirname "$0")/config/config.json"

    if [[ ! -f "$CONFIG_FILE" ]]; then
        local default_config
        default_config=$(
            jq -n '{
                backupDrive: {
                    letter: "",
                    name: "",
                    size: ""
                },
                backupFolder: "Backup",
                sources: [],
                language: "en"
            }'
        )

        printf '%s\n' "$default_config" > "$CONFIG_FILE"
        printf '%s\n' "$default_config"
        return 0
    fi

    if ! jq empty "$CONFIG_FILE" >/dev/null 2>&1; then
        echo "failed"
        return 1
    fi

    cat "$CONFIG_FILE"
}


Show-Config() {
    local config
    if ! config=$(Get-Config); then
        echo "failed"
        return 1
    fi

    clear

    echo "current config"

    local letter name size folder lang
    letter=$(jq -r '.backupDrive.letter // ""' <<< "$config")
    name=$(jq -r '.backupDrive.name // ""' <<< "$config")
    size=$(jq -r '.backupDrive.size // ""' <<< "$config")
    folder=$(jq -r '.backupFolder // ""' <<< "$config")
    lang=$(jq -r '.language // ""' <<< "$config")

    echo "Backup Drive :"
    if [[ -z "$letter" ]]; then 
        echo "   No Backup Drive"
    else
        echo "   Letter : $letter"
        echo "   Name : $name"
        echo "   Size : $size"
    fi

    echo "Folder : $folder"
    
    echo "Sources :"
    local source_count
    source_count=$(jq '.sources | length' <<< "$config")
    if [[ "$source_count" -eq 0 ]]; then
        echo "   No Sources"
    else
        jq -r '.sources[]' <<< "$config" | while IFS= read -r src; do
            echo "   $src"
        done
    fi

    echo "Language : $lang"
}


Save-Config() {
    local config="$1"

    if [[ -z "$config" ]]; then
        echo "Error"
        return 1
    fi

    if ! jq empty <<< "$config" 2>/dev/null; then
        echo "Error"
        return 1
    fi

    jq '.' <<< "$config" > "$CONFIG_PATH"
    echo "success save"
}

