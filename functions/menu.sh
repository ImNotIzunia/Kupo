#!/bin/bash

# SYNOPSIS
# Moogle - Menus management functions
#
# DESCRIPTION
# Provide the functions to show the different menus
#
# NOTES
# Author  : Izunia
# Version : 1.0.0
# License : MIT License



# SYNOPSIS
# Displays the main menu
#
# DESCRIPTION
# Loops and prompts the user to start a backup, open the
# configuration menu, the language menu or exist the application
#
# EXAMPLE
# Show-MainMenu
#
# OUTPUTS
# None
#
Show-MainMenu() {

    while true; do
        echo ""

        echo "1. $(Get-String "main.startBackup")"
        echo "2. $(Get-String "main.config")"
        echo "3. $(Get-String "main.lang")"
        echo "4. $(Get-String "main.exit")"

        echo ""

        read -rp "$(Get-String "main.choice") : " choice 

        case "$choice" in
            1)
                clear
                Write-Log "Menu - Start Backup" "INFO"
                Start-Backup
                ;;

            2)
                clear
                Write-Log "Menu - Show Config" "INFO"
                Show-ConfigMenu
                ;;
            
            3)
                clear
                Write-Log "Menu - Show Language" "INFO"
                Show-LangMenu
                ;;
            
            4)
                clear
                Write-Log "Menu - Exit" "INFO"
                exit 0
                ;;
            
            *)
                clear
                Write-Log "Menu - Invalid Choice" "ERROR"
                Get-String "main.invalid"
                sleep 1
                ;;
        esac
    done
}


# SYNOPSIS
# Displays the configuration menu
#
# DESCRIPTION
# Loops and prompts the user to view the configuration,
# manage the backup drive and soruces or return to the main menu
#
# EXAMPLE
# Show-ConfigMenu
#
# OUTPUTS
# None
#
Show-ConfigMenu() {

    while true; do
        echo ""

        echo "========================="
        echo ""
        echo "      Configuration"
        echo ""
        echo "========================="

        echo "1. $(Get-String "configmenu.view")"
        echo "2. $(Get-String "configmenu.drive")"
        echo "3. $(Get-String "configmenu.source")"
        echo "4. $(Get-String "configmenu.back")"

        echo ""

        read -rp "$(Get-String "configmenu.choice") : " choice

        case "$choice" in
            1)
                clear
                Write-Log "Menu - Show Config" "INFO"
                Show-Config
                ;;

            2)
                clear
                Write-Log "Menu - Show Backup" "INFO"
                Show-BackupMenu
                ;;

            3)
                clear
                Write-Log "Menu - Show Sources" "INFO"
                Show-SourceMenu
                ;;

            4)
                clear
                Write-Log "Menu - Exit" "INFO"
                return
                ;;

            *)
                clear
                Write-Log "Menu - Invalid Choice" "ERROR"
                Get-String "configmenu.invalid"
                sleep 1
                ;;
        esac
    done
}


# SYNOPSIS
#
# Displays the backup drive menu
#
# DESCRIPTION
# Loops and prompts the user to view the backup drive,
# change the backup drive or folder or return to the config menu
#
# EXAMPLE
# Show-BackupMenu
#
# OUTPUTS
# None
#
Show-BackupMenu() {

    while true; do
        echo ""

        echo "=========================="
        echo ""
        echo "      Backup options"
        echo ""
        echo "=========================="

        echo "1. $(Get-String "backmenu.view")"
        echo "2. $(Get-String "backmenu.changedrive")"
        echo "3. $(Get-String "backmenu.changefolder")"
        echo "4. $(Get-String "backmenu.back")"

        echo ""

        read -rp "$(Get-String "backmenu.choice") : " choice

        case "$choice" in
            1)
                clear
                Write-Log "Menu - Show Backup" "INFO"
                Show-BackupDrive
                ;;

            2)
                clear
                Write-Log "Menu - Change Drive" "INFO"
                Set-BackupDrive
                ;;

            3)
                clear
                Write-Log "Menu - Change Folder" "INFO"
                Set-BackupFolder
                ;;

            4)
                clear
                Write-Log "Menu - Exit" "INFO"
                return
                ;;

            *)
                clear
                Write-Log "Menu - Invalid Choice" "ERROR"
                Get-String "backmenu.invalid"
                sleep 1
                ;;
        esac
    done
}


# SYNOPSIS
# Displays the sources menu
#
# DESCRIPTION
# Loops and prompts the user to view, add or remove
# backup source folders or return to config menu
#
# EXAMPLE
# Show-SourcesMenu
#
# OUTPUTS
# None
#
Show-SourceMenu() {

    while true; do
        echo ""

        echo "=========================="
        echo ""
        echo "      Sources options"
        echo ""
        echo "=========================="

        echo "1. View"
        echo "2. Add a new source"
        echo "3. Remove a source"
        echo "4. Back"

        echo ""

        read -rp "Select an option (1-4) : " choice

        case "$choice" in
            1)
                clear
                Write-Log "Menu - Show Source" "INFO"
                Get-Source
                ;;

            2)
                clear
                Write-Log "Menu - Add Source" "INFO"
                Add-Source
                ;;

            3)
                clear
                Write-Log "Menu - Remove Source" "INFO"
                Delete-Source
                ;;

            4)
                clear
                Write-Log "Menu - Exit" "INFO"
                return
                ;;

            *)
                clear
                Write-Log "Menu - Invalid Choice" "ERROR"
                Get-String "sourcemenu.invalid"
                sleep 1
                ;;
        esac
    done
}


# SYNOPSIS
# Displays the language menu
#
# DESCRIPTION
# Loops and prompts the user to switch the application language to
# French or English or return to the main menu
#
# EXAMPLE
# Show-LangMenu
#
# OUTPUTS
# None
#
Show-LangMenu() {

    while true; do
        echo ""

        echo "=============================="
        echo ""
        echo "      Languages settings"
        echo ""
        echo "=============================="

        echo "1. $(Get-String "lang.fr")"
        echo "2. $(Get-String "lang.eng")"
        echo "3. $(Get-String "lang.back")"

        echo ""

        read -rp "$(Get-String "lang.choice") : " choice

        case "$choice" in
            1)
                clear
                Write-Log "Menu - Change French" "INFO"
                Set-Language "fr"
                ;;

            2)
                clear
                Write-Log "Menu - Change English" "INFO"
                Set-Language "en"
                ;;

            3)
                clear
                Write-Log "Menu - Exit" "INFO"
                return
                ;;

            *)
                clear
                Write-Log "Menu - Invalid Choice" "ERROR"
                Get-String "lang.invalid"
                sleep 1
                ;;
        esac
    done
}

