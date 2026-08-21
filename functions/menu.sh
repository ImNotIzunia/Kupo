#!/bin/bash

Show-MainMenu() {

    while true; do
        echo "1. Start Backup"
        echo "2. Configuration"
        echo "3. Languages"
        echo "4. Exit"

        read -rp "Select an option (1-4) : " choice 

        case "$choice" in
            1)
                clear
                Start-Backup
                ;;

            2)
                clear
                Show-ConfigMenu
                ;;
            
            3)
                clear
                Show-LangMenu
                ;;
            
            4)
                clear
                echo "Exit"
                exit 0
                ;;
            
            *)
                clear
                echo "[ERROR] Invalid choice"
                sleep 1
                ;;
        esac
    done
}


Show-ConfigMenu() {

    while true; do
        echo ""

        echo "========================="
        echo ""
        echo "      Configuration"
        echo ""
        echo "========================="

        echo "1. View"
        echo "2. Drive"
        echo "3. Sources"
        echo "4. Back"

        echo ""

        read -rp "Select an option (1-4) : " choice

        case "$choice" in
            1)
                clear
                Show-Config
                ;;
            2)
                clear
                Show-BackupMenu
                ;;
            3)
                clear
                Show-SourceMenu
                ;;
            4)
                clear
                echo "Back to main menu"
                return
                ;;
            *)
                clear
                echo "[ERROR] Invalid choice"
                sleep 1
                ;;
        esac
    done
}


Show-BackupMenu() {

    while true; do
        echo ""

        echo "=========================="
        echo ""
        echo "      Backup options"
        echo ""
        echo "=========================="

        echo "1. View current backup"
        echo "2. Change backup drive"
        echo "3. Change backup folder"
        echo "4. Back"

        echo ""

        read -rp "Select an option (1-4) : " choice

        case "$choice" in
            1)
                clear
                Show-BackupDrive
                ;;
            2)
                clear
                Set-BackupDrive
                ;;
            3)
                clear
                Set-BackupFolder
                ;;
            4)
                clear
                echo "Return to Previous menu"
                return
                ;;
            *)
                clear
                echo "[ERROR] Invalid choice"
                sleep 1
                ;;
        esac
    done
}


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

        read -rp "Select an option (1-4) : " choice

        case "$choice" in
            1)
                clear
                Get-Source
                ;;
            2)
                clear
                Add-Source
                ;;
            3)
                clear
                Delete-Source
                ;;
            4)
                clear
                echo "Return to previous Menu"
                return
                ;;
            *)
                clear
                echo "[ERROR] Invalid Choice"
                sleep 1
                ;;
        esac
    done
}


Show-LangMenu() {

    while true; do
        echo ""

        echo "=============================="
        echo ""
        echo "      Languages settings"
        echo ""
        echo "=============================="

        echo "1. French"
        echo "2. English"
        echo "3. Back"

        read -rp "Select an option (1-3) : " choice

        case "$choice" in
            1)
                clear
                echo "[INFO] Set to French"
                ;;
            2)
                clear
                echo "[INFO] Set to English"
                ;;
            3)
                clear
                echo "Back to Main Menu"
                return
                ;;
            *)
                clear
                echo "[ERROR] Invalid choice"
                sleep 1
                ;;
        esac
    done
}