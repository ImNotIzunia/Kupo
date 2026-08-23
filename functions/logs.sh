#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../logs"


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


