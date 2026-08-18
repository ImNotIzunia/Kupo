Get-Source() {
    local config
    if ! config=$(Get-Config); then
        echo "failed"
        return 1
    fi

    local source_count
    source_count=$(jq '.sources | length' <<< "$config")
    if [[ "$source_count" -eq 0 ]]; then
        echo "   No Sources"
    else
        jq -r '.sources[]' <<< "$config" | nl -w 1 -s'. '
    fi
}


Add-Source() {
    local path
    local resolved_path
    local config
    local new_config
    if ! config=$(Get-Config); then
        echo "failed"
        return 1
    fi

    if ! IFS= read -rp "Enter the full path of the folder to add: " path; then
        path=""
    fi

    if [[ -z "${path//[[:space:]]/}" ]]; then
        echo "failed"
        return 1
    fi

    if [[ ! -d "$path" ]]; then
        echo "not found"
        return 1
    fi

    if ! resolved_path="$(cd -- "$path" 2>/dev/null && pwd -P)"; then
        echo "not resolved"
        return 1
    fi

    if jq -e --arg path "$resolved_path" '.sources | index($path)' <<<"$config" >/dev/null; then
        echo "already exists"
        return 1
    fi

    new_config=$(
        jq --arg path "$resolved_path" \
           '.sources += [$path]' <<<"$config"
    )

    if ! Save-Config "$new_config"; then
        echo "failed to save"
        return 1
    fi

    echo "success"
}


Delete-Source() {
    local config
    local source_count
    local choice
    local new_config
    if ! config=$(Get-Config); then
        echo "failed"
        return 1
    fi

    source_count=$(jq '.sources | length' <<<"$config")

    if [[ "$source_count" -eq 0 ]]; then
        echo "No sources"
        return 1
    fi

    Get-Source
    echo

    if ! IFS= read -rp "Enter the number of the source to remove : " choice; then
        choice=""
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > source_count )); then
        echo "invalid"
        return 1
    fi

    new_config=$(jq --argjson index "$((choice -1))" \ 'del(.sources[$index])' <<< "$config")

    if ! Save-Config "$new_config"; then
        echo "failed to save"
        return 1
    fi

    echo "success"
}

