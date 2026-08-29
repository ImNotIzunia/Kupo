#!/bin/bash

# SYNOPSIS
# Kupo - Dependencies management functions
#
# DESCRIPTION
# Provide functions to check if the dependencies are installed
# If not ask the user if he want to install them
#
# NOTES
# Author  : Izunia
# Version : 1.0.0
# License : MIT License


REQUIRED_DEPS=(
    "jq"
    "bc"
    "zip"
)


# SYNOPSIS
# Check if the dependencies are installed
# 
# DESCRIPTION
# Check for the needed dependencies if not installed
# ask the user if he want to install them
# They are needed to run the project
# 
# EXAMPLE
# Check-Dependencies
# 
# OUTPUTS
# echo
#
Check-Dependencies() {
    local missing=()

    for dependency in "${REQUIRED_DEPS[@]}"
    do
        if ! command -v "$dependency" >/dev/null 2>&1; then
            missing+=("$dependency")
        fi
    done

    if (( ${#missing[@]} == 0 )); then
        return 0
    fi

    echo
    echo "Missing Dependencies for the project : "
    echo

    for dependency in "${missing[@]}"
    do
        echo "  - $dependency"
    done

    echo

    read -rp "Do you want to install them ? [Y/n]" answer

    if [[ "$answer" =~ ^[Yy] || -z "$answer" ]]; then
        Install-Dependencies "${missing[@]}"
        return $?
    fi

    echo "Kupo cannot start without these dependencies."
    return 1
}


# SYNOPSIS
# Install missing dependencies
#
# DESCRIPTION
# Look for the package manager and try to
# isntall the missing dependencies
#
# EXAMPLE
# Install-Dependencies
# 
# OUTPUTS
# echo
#
Install-Dependencies() {
    local dependencies=("$@")

    echo
    echo "Installing dependencies..."
    echo

    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update

        if ! sudo apt-get install -y "${dependencies[@]}"; then
            echo
            echo "Failed to install dependencies"
            return 1
        fi
    
    elif command -v pacman >/dev/null 2>&1; then

        if ! sudo pacman -S --needed --noconfirm "${dependencies[@]}"; then
            echo
            echo "Failed to install dependencies."
            return 1
        fi

    else
        echo "Unsupported package manager."
        echo "Please install the dependencies manually:"
        echo

        printf '  %s\n' "${dependencies[@]}"

        return 1
    fi

    echo
    echo "Dependencies installed successfully"

    for dependency in "${dependencies[@]}"
    do
        if ! command -v "$dependency" >/dev/null 2>&1; then
            echo "Dependency still missing : $dependency"
            return 1
        fi
    done

    return 0
}




