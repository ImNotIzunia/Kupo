#!/bin/bash

# SYNOPSIS
# Kupo - Progress bar management functions
#
# DESCRIPTION
# Provide the functions to show the progress bar during downloads
#
# NOTES
# Author  : Izunia
# Version : 1.0.0
# License : MIT License



# SYNOPSIS
# Displays a progress bar in the console
#
# DESCRIPTION
# Renders a text-based progress bar showing the completion percentage
# along with an activity label and status message
# 
# PARAMETER Current
# The current progress value
#
# PARAMETER Total
# The total value representing 100% completion
# If less than or equal to 0 nothing is displayed
#
# PARAMETER Activity
# The label describing the ongoing activity
#
# PARAMETER Status
# The status message displayed after the percentage
#
# EXAMPLE
# Show-ProgressBar "$current" "$total" "Compressing" "$source_name ($current/$total)"
#
# OUTPUTS
# None
#
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


