#!/bin/bash

# SYNOPSIS
# Moogle - Logs management functions
#
# DESCRIPTION
# Provide the functions to logs the actions and infos
#
# NOTES
# Author  : Izunia
# Version : 1.0.0
# License : MIT License



SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../logs"


# SYNOPSIS
# Initializes the log file for the current day
#
# DESCRIPTION
# Creates the logs folder and log file for 
# the current day if they don't already exist
#
# EXAMPLE
# Init-Log
#
# OUTPUTS
# None
#
Init-Log() {
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR"
    fi

    local log_file

    log_file="$LOG_DIR/moogle_$(date +'%Y-%m-%d').log"

    if [[ ! -f "$log_file" ]]; then
        touch "$log_file"
    fi

    (cd "$LOG_DIR" && echo "$(pwd)/$(basename "$log_file")")
}


# SYNOPSIS
# Writes a message to the log file
#
# DESCRIPTION
# Initializes the log file for the current day and
# appends a timestamped entry to it prefixed with the specified level
#
# PARAMETER Message
# The message to write to the log
#
# PARAMETER Level
# The severity level of the log entry
# Must be one of INFO, WARNING, ERROR, SUCCESS
# Defaults to INFO
# 
# EXAMPLE
# Write-Log "Message" "SUCCESS"
#
# OUTPUTS
# None
#
Write-Log() {
    local message="$1"
    local level="${2:-INFO}"

    if [[ -z "$message" ]]; then
        echo "Error: Write-Log requires a message" >&2
        return 1
    fi

    case "$level" in
        INFO|WARNING|ERROR|SUCCESS) ;;
        *)
            echo "Error: level must be one of INFO, WARNING, ERROR, SUCCESS" >&2
            return 1
            ;;
    esac

    local log_file
    log_file="$(Init-Log)"

    local timestamp
    timestamp="$(date +'%Y-%m-%d %H:%M:%S')"

    echo "[$timestamp] [$level] $message" >> "$log_file"
}


