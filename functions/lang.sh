#!/bin/bash

# SYNOPSIS
# Kupo - Language functions
#
# DESCRIPTION
# Provide functions to load, cache and retrieve translated strings
# based on the language configured by the user
# 
# NOTES
# Author  : Izunia
# Version : 1.0.0
# License : MIT License



SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LANG_DIR="$SCRIPT_DIR/../lang"


_STRINGS_JSON=""


# SYNOPSIS
# Loads the translation strings for the configured language
#
# DESCRIPTION
# Reads the configured language from the config file and
# loads the matching JSON from the lang folder
# Falls back to English if the configured language file is
# missing or if no language is configured
#
# EXAMPLE
# Init-Language
#
# OUTPUTS
# None
#
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


# SYNOPSIS
# Retrieves a translated string by its dotted key
#
# DESCRIPTION
# Looks up a translation using a dotted key path in
# the currently loaded language strings
# Loads the language automatically on first use
# Returns the key itself if no matching translation is found
#
# PARAMETER Key
# The dotted path of the string to retrieve
#
# EXAMPLE
# Get-String "main.startBackup"
#
# OUTPUTS
# echo
#
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


# SYNOPSIS
# Changes the application language
#
# DESCRIPTION
# Saves the given language code to the configuration and 
# reloads the translation strings accordingly
#
# PARAMETER Code
# The language code to switch to ("fr" or "en")
#
# EXAMPLE
# Set-Language "fr"
#
# OUTPUTS
# None
# 
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



