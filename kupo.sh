#!/bin/bash

set -e

source "$(dirname "$0")/functions/dependencies.sh"

if ! Check-Dependencies; then
    exit 1
fi

source "$(dirname "$0")/functions/logo.sh"
source "$(dirname "$0")/functions/menu.sh"
source "$(dirname "$0")/functions/config.sh"
source "$(dirname "$0")/functions/sources.sh"
source "$(dirname "$0")/functions/drive.sh"
source "$(dirname "$0")/functions/compress.sh"

Show-Banner
Show-MainMenu
