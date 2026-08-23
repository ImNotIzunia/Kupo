#!/bin/bash

Show-ProgressBar() {
    local current="$1"
    local total="$2"
    local activity="$3"
    local status="$4"
    
    if (( total <= 0 )); then
    return 0
    fi
    
    local percent=$((current * 100 / total))
    local bar_width=30
    
    if (( percent < 0 )); then
    percent=0
    elif (( percent > 100 )); then
    percent=100
    fi
    
    local filled=$((percent * bar_width / 100))
    local empty=$((bar_width - filled))
    
    local bar
    bar=$(printf '%*s' "$filled" '' | tr ' ' '#')
    bar+=$(printf '%*s' "$empty" '' | tr ' ' '-')
    
    printf '\r%s [%s] %3d%% - %s\033[K' \
    "$activity" \
    "$bar" \
    "$percent" \
    "$status"
}


