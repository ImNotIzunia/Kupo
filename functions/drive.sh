#!/bin/bash

Format-StorageSize() {
    local size="$1"

    if (( $(echo "$size >= 1000" | bc -l) )); then
        printf "%.1fTo\n" "$(echo "$size / 1000" | bc -l)"
    else
        printf "%dGo\n" "$size"
    fi
}


Get-ExternalDrives() {
    lsblk -nr -o NAME,TYPE,SIZE,LABEL,UUID,MOUNTPOINTS |
    awk '$2 == "part" && $6 != "" {
        print $1 "|" $3 "|" $4 "|" $5 "|" $6
    }'
}


Show-BackupDrive() {
    local config

    if ! config=$(Get-Config); then
        echo "failed"
        return 1
    fi

    local uuid
    local name
    local size

    uuid=$(jq -r '.backupDrive.uuid // ""' <<< "$config")
    name=$(jq -r '.backupDrive.name // ""' <<< "$config")
    size=$(jq -r '.backupDrive.size // ""' <<< "$config")

    if [[ -z "$uuid" ]]; then
        echo "Aucun backup"
        return 0
    fi

    echo "Disque actuel :"
    echo "  Name : $name"
    echo "  UUID : $uuid"
    echo "  Size : $size"
}


Set-BackupDrive() {

    local config

    if ! config=$(Get-Config); then
        echo "failed"
        return 1
    fi

    mapfile -t drives < <(Get-ExternalDrives)

    if [[ ${#drives[@]} -eq 0 ]]; then
        echo "Aucun disque trouvé"
        return 0
    fi

    echo "Disques dispo :"
    echo

    for i in "${!drives[@]}"
    do
        IFS="|" read -r name size label uuid mountpoint <<< "${drives[$i]}"

        printf "%d - %s (%s - %s)\n" \
            "$((i + 1))" \
            "${label:-Sans nom}" \
            "$size" \
            "$mountpoint"
    done

    echo

    read -rp "Choix : " choice

    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo "Choix invalide"
        return 1
    fi

    local index=$((choice - 1))

    if (( index < 0 || index >= ${#drives[@]} )); then
        echo "Choix invalide"
        return 1
    fi

    IFS="|" read -r name size label uuid mountpoint <<< "${drives[$index]}"

    if [[ -z "$uuid" ]]; then
        echo "Impossible de récupérer l'UUID"
        return 1
    fi

    config=$(
        jq \
            --arg uuid "$uuid" \
            --arg name "${label:-Sans nom}" \
            --arg size "$size" \
            '
            .backupDrive.uuid = $uuid |
            .backupDrive.name = $name |
            .backupDrive.size = $size
            ' <<< "$config"
    )

    if [[ -z "$config" ]]; then
        echo "Erreur lors de la mise à jour"
        return 1
    fi

    if ! Save-Config "$config"; then
        return 1
    fi

    echo
    echo "Disque sélectionné : ${label:-Sans nom}"
    echo "UUID : $uuid"
    echo "Taille : $size"
    echo "Monté sur : $mountpoint"
}


Set-BackupFolder() {

    local config

    if ! config=$(Get-Config); then
        echo "failed"
        return 1
    fi

    local current_folder

    current_folder=$(jq -r '.backupFolder // ""' <<< "$config")

    echo "Dossier actuel : $current_folder"
    echo

    read -rp "New dossier : " folder

    if [[ -z "$folder" ]]; then
        folder="$current_folder"
    fi

    config=$(
        jq \
            --arg folder "$folder" \
            '.backupFolder = $folder' \
            <<< "$config"
    )

    Save-Config "$config"

    echo
    echo "Dossier de save : $folder"
}


