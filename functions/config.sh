#!/bin/bash

Get-Config-Path() {
    local script_dir
    script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
    printf '%s/config/config.json\n' "$script_dir"
}



Get-Config() {
    local config_file
    config_file=$(Get-Config-Path)

    if [[ ! -f "$config_file" ]]; then
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

        printf '%s\n' "$default_config" > "$config_file"
        printf '%s\n' "$default_config"
        return 0
    fi

    if ! jq empty "$config_file" >/dev/null 2>&1; then
        echo "failed"
        return 1
    fi

    cat "$config_file"
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
    local config_file

    config_file=$(Get-Config-Path)

    if [[ -z "$config" ]]; then
        echo "Error"
        return 1
    fi

    if ! jq empty <<< "$config" 2>/dev/null; then
        echo "Error"
        return 1
    fi

    if ! jq '.' <<<"$config" >"$config_file"; then
        echo "Error while saving"
        return 1
    fi

    echo "success save"
}

