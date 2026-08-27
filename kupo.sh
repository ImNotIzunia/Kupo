#!/bin/bash

# ============================================================
# Kupo - Launcher
#
#
# Loads all the functions modules, initializes the log file
# then displays the application and main menu
#
#
# Author  : Izunia
# Version : 1.0.0
# License : MIT License
# ============================================================

set -e

source "$(dirname "$0")/functions/dependencies.sh"

if ! Check-Dependencies; then
    exit 1
fi

source "$(dirname "$0")/functions/logs.sh"
source "$(dirname "$0")/functions/logo.sh"
source "$(dirname "$0")/functions/lang.sh"
source "$(dirname "$0")/functions/menu.sh"
source "$(dirname "$0")/functions/config.sh"
source "$(dirname "$0")/functions/sources.sh"
source "$(dirname "$0")/functions/drive.sh"
source "$(dirname "$0")/functions/progress.sh"
source "$(dirname "$0")/functions/compress.sh"
source "$(dirname "$0")/functions/backup.sh"

Show-Banner
Show-MainMenu
