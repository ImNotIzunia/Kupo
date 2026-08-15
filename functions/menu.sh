#!/bin/bash

Show-MainMenu() {

    while true; do
        echo "1. Start Backup"
        echo "2. Configuration"
        echo "3. Languages"
        echo "4. Exit"

        read -rp "Select an option (1-4): " choice 

        case "$choice" in
            1)
                clear
                echo "[INFO] Start Backup"
                ;;

            2)
                clear
                echo "[INFO] Settings"
                ;;
            
            3)
                clear
                echo "[INFO] Languages"
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