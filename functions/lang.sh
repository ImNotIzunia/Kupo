#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LANG_DIR="$SCRIPT_DIR/../lang"


_STRINGS_JSON=""


Init-Language() {
    local config
    config="$(Get-Config)"

    local lang_code
    lang_code="$(jq -r '.language // empty' <<<"$config")"

    if [[ -z "$lang_code" ]]; then
        lang_code="en"
    fi

    local lang_path="$LANG_DIR/$lang_code.json"

    if [[ ! -f "$lang_path" ]]; then
        lang_path="$LANG_DIR/en.json"
    fi

    _STRINGS_JSON="$(<"$lang_path")"
}


Get-String() {
    local key="$1"

    if [[ -z "$key" ]]; then
        echo "Error: get_string requires a key" >&2
        return 1
    fi

    if [[ -z "$_STRINGS_JSON" ]]; then
        Init-Language
    fi

    local jq_filter=".${key}"

    local value
    value="$(jq -r "$jq_filter // empty" <<<"$_STRINGS_JSON" 2>/dev/null)"

    if [[ -z "$value" ]]; then
        echo "$key"
    else
        echo "$value"
    fi
}


Set-Language() {
    local code="$1"

    if [[ "$code" != "fr" && "$code" != "en" ]]; then
        echo "Error: language code must be 'fr' or 'en'" >&2
        return 1
    fi

    local config
    config="$(Get-Config)"

    local updated_config
    updated_config="$(jq --arg code "$code" '.language = $code' <<<"$config")"

    Save-Config "$updated_config"

    Init-Language
}



