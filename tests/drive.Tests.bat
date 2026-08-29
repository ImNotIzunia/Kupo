#!/usr/bin/env bats

setup() {
    TEST_DIR="$(mktemp -d)"

    CONFIG_FILE="$TEST_DIR/config.json"

    TEST_CONFIG='{
        "backupDrive": {
            "uuid": "",
            "name": "",
            "size": ""
        },
        "backupFolder": "Backup",
        "sources": [],
        "language": "en"
    }'
    printf '%s\n' "$TEST_CONFIG" > "$CONFIG_FILE"

    source "$BATS_TEST_DIRNAME/../functions/drive.sh"

    # --------------------------------------------------------
    # Stand-ins for helpers normally provided by other Kupo
    # modules (logging.sh / i18n.sh) that aren't sourced here.
    # Swap these for the real modules if/when they're sourced.
    # --------------------------------------------------------

    Write-Log() { :; }

    Get-String() {
        case "$1" in
            drive.nodrive)        echo "Aucun backup" ;;
            drive.actual)         echo "Disque actuel :" ;;
            drive.drivename)      echo "Name" ;;
            drive.driveuuid)      echo "UUID" ;;
            drive.drivesize)      echo "Size" ;;
            drive.notfound)       echo "Aucun disque trouvé" ;;
            drive.founddrive)     echo "Disques dispo :" ;;
            drive.choice)         echo "Choix" ;;
            drive.invalidchoice)  echo "Choix invalide" ;;
            drive.cantuuid)       echo "Impossible de récupérer l'UUID" ;;
            drive.configfailed)   echo "failed" ;;
            drive.savefailed)     echo "failed" ;;
            drive.driveselected)  echo "Disque sélectionné" ;;
            drive.drivetaille)    echo "Taille" ;;
            drive.drivemounted)   echo "Monté sur" ;;
            drive.drivesuccess)   echo "Disque de sauvegarde configuré avec succès" ;;
            drive.currentfolder)  echo "Dossier actuel" ;;
            drive.folderchoice)   echo "Nouveau dossier" ;;
            drive.folderchange)   echo "Dossier de sauvegarde mis à jour" ;;
            *)                    echo "$1" ;;
        esac
    }

    Get-Config() {
        cat "$CONFIG_FILE"
    }

    Save-Config() {
        printf '%s\n' "$1" > "$CONFIG_FILE"
    }

    clear() {
        :
    }
}

teardown() {
    rm -rf "$TEST_DIR"
}


# ============================================================
# Format-StorageSize
# ============================================================

@test "Format-StorageSize: formats gigabytes below 1000" {
    run Format-StorageSize 500
    [ "$status" -eq 0 ]
    [ "$output" = "500Go" ]
}

@test "Format-StorageSize: formats zero gigabytes" {
    run Format-StorageSize 0
    [ "$status" -eq 0 ]
    [ "$output" = "0Go" ]
}

@test "Format-StorageSize: formats value just below 1000 GB" {
    run Format-StorageSize 999
    [ "$status" -eq 0 ]
    [ "$output" = "999Go" ]
}

@test "Format-StorageSize: converts 1000 GB to terabytes" {
    run Format-StorageSize 1000
    [ "$status" -eq 0 ]
    [ "$output" = "1.0To" ]
}

@test "Format-StorageSize: converts value above 1000 GB to terabytes" {
    run Format-StorageSize 1500
    [ "$status" -eq 0 ]
    [ "$output" = "1.5To" ]
}

@test "Format-StorageSize: formats decimal gigabytes below 1000" {
    run Format-StorageSize 500.5
    [ "$status" -eq 0 ]
    [ "$output" = "501Go" ]
}

@test "Format-StorageSize: formats large storage size" {
    run Format-StorageSize 2000
    [ "$status" -eq 0 ]
    [ "$output" = "2.0To" ]
}


# ============================================================
# Get-ExternalDrives
# ============================================================

@test "Get-ExternalDrives: returns mounted partitions" {
    lsblk() {
        cat <<'EOF'
sda disk 500G System - -
sda1 part 500G Backup ABCD-1234 /mnt/backup
EOF
    }
    run Get-ExternalDrives
    [ "$status" -eq 0 ]
    [ "$output" = "sda1|500G|Backup|ABCD-1234|/mnt/backup" ]
}

@test "Get-ExternalDrives: ignores non-partition devices" {
    lsblk() {
        cat <<'EOF'
sda disk 500G System - -
sda1 part 500G Backup ABCD-1234 /mnt/backup
sdb disk 1T Data - -
EOF
    }
    run Get-ExternalDrives
    [ "$status" -eq 0 ]
    [ "$output" = "sda1|500G|Backup|ABCD-1234|/mnt/backup" ]
}

@test "Get-ExternalDrives: ignores unmounted partitions" {
    lsblk() {
        cat <<'EOF'
sda1 part 500G Backup ABCD-1234 /mnt/backup
sdb1 part 1T Data EFGH-5678
EOF
    }
    run Get-ExternalDrives
    [ "$status" -eq 0 ]
    [ "$output" = "sda1|500G|Backup|ABCD-1234|/mnt/backup" ]
}

@test "Get-ExternalDrives: ignores partitions without mountpoint" {
    lsblk() {
        cat <<'EOF'
sda1 part 500G Backup ABCD-1234
EOF
    }
    run Get-ExternalDrives
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "Get-ExternalDrives: preserves multiple drives order" {
    lsblk() {
        cat <<'EOF'
sda1 part 500G Backup UUID-1 /mnt/one
sdb1 part 1T Data UUID-2 /mnt/two
sdc1 part 2T Archive UUID-3 /mnt/three
EOF
    }
    run Get-ExternalDrives
    [ "$status" -eq 0 ]
    expected=$'sda1|500G|Backup|UUID-1|/mnt/one\nsdb1|1T|Data|UUID-2|/mnt/two\nsdc1|2T|Archive|UUID-3|/mnt/three'
    [ "$output" = "$expected" ]
}

@test "Get-ExternalDrives: handles empty lsblk output" {
    lsblk() {
        :
    }
    run Get-ExternalDrives
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}


# ============================================================
# Show-BackupDrive
# ============================================================

@test "Show-BackupDrive: reports no backup drive when UUID is missing" {
    run Show-BackupDrive
    [ "$status" -eq 0 ]
    [ "$output" = "Aucun backup" ]
}

@test "Show-BackupDrive: displays configured backup drive" {
    TEST_CONFIG='{
        "backupDrive": {
            "uuid": "ABCD-1234",
            "name": "Backup Drive",
            "size": "1TB"
        },
        "backupFolder": "Backup",
        "sources": [],
        "language": "en"
    }'
    printf '%s\n' "$TEST_CONFIG" > "$CONFIG_FILE"
    run Show-BackupDrive
    [ "$status" -eq 0 ]
    [[ "$output" == *"Disque actuel :"* ]]
    [[ "$output" == *"Name : Backup Drive"* ]]
    [[ "$output" == *"UUID : ABCD-1234"* ]]
    [[ "$output" == *"Size : 1TB"* ]]
}

@test "Show-BackupDrive: reports Get-Config failure" {
    Get-Config() {
        return 1
    }
    run Show-BackupDrive
    [ "$status" -eq 1 ]
    [ "$output" = "failed" ]
}

@test "Show-BackupDrive: handles missing backupDrive object" {
    TEST_CONFIG='{
        "backupFolder": "Backup",
        "sources": [],
        "language": "en"
    }'
    printf '%s\n' "$TEST_CONFIG" > "$CONFIG_FILE"
    run Show-BackupDrive
    [ "$status" -eq 0 ]
    [ "$output" = "Aucun backup" ]
}


# ============================================================
# Set-BackupDrive
# ============================================================

@test "Set-BackupDrive: reports no drives found" {
    Get-ExternalDrives() {
        :
    }
    run Set-BackupDrive
    [ "$status" -eq 0 ]
    [ "$output" = "Aucun disque trouvé" ]
}

@test "Set-BackupDrive: lists available drives" {
    Get-ExternalDrives() {
        printf '%s\n' \
            "sda1|500G|Backup|UUID-1|/mnt/backup" \
            "sdb1|1T|Data|UUID-2|/mnt/data"
    }
    printf '1\n' > "$TEST_DIR/input"
    run Set-BackupDrive < "$TEST_DIR/input"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Disques dispo :"* ]]
    [[ "$output" == *"1 - Backup (500G - /mnt/backup)"* ]]
    [[ "$output" == *"2 - Data (1T - /mnt/data)"* ]]
}

@test "Set-BackupDrive: selects first drive" {
    Get-ExternalDrives() {
        printf '%s\n' \
            "sda1|500G|Backup|UUID-1|/mnt/backup" \
            "sdb1|1T|Data|UUID-2|/mnt/data"
    }
    printf '1\n' > "$TEST_DIR/input"
    run Set-BackupDrive < "$TEST_DIR/input"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Disque sélectionné : Backup"* ]]
    [[ "$output" == *"UUID : UUID-1"* ]]
    [[ "$output" == *"Taille : 500G"* ]]
    [[ "$output" == *"Monté sur : /mnt/backup"* ]]
    run jq -e '
        .backupDrive.uuid == "UUID-1" and
        .backupDrive.name == "Backup" and
        .backupDrive.size == "500G"
    ' "$CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "Set-BackupDrive: selects last drive" {
    Get-ExternalDrives() {
        printf '%s\n' \
            "sda1|500G|Backup|UUID-1|/mnt/backup" \
            "sdb1|1T|Data|UUID-2|/mnt/data"
    }
    printf '2\n' > "$TEST_DIR/input"
    run Set-BackupDrive < "$TEST_DIR/input"
    [ "$status" -eq 0 ]
    run jq -e '
        .backupDrive.uuid == "UUID-2" and
        .backupDrive.name == "Data" and
        .backupDrive.size == "1T"
    ' "$CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "Set-BackupDrive: rejects non numeric choice" {
    Get-ExternalDrives() {
        printf '%s\n' "sda1|500G|Backup|UUID-1|/mnt/backup"
    }
    printf 'abc\n' > "$TEST_DIR/input"
    run Set-BackupDrive < "$TEST_DIR/input"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Choix invalide"* ]]
}

@test "Set-BackupDrive: rejects empty choice" {
    Get-ExternalDrives() {
        printf '%s\n' "sda1|500G|Backup|UUID-1|/mnt/backup"
    }
    printf '\n' > "$TEST_DIR/input"
    run Set-BackupDrive < "$TEST_DIR/input"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Choix invalide"* ]]
}

@test "Set-BackupDrive: rejects choice below minimum" {
    Get-ExternalDrives() {
        printf '%s\n' "sda1|500G|Backup|UUID-1|/mnt/backup"
    }
    printf '0\n' > "$TEST_DIR/input"
    run Set-BackupDrive < "$TEST_DIR/input"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Choix invalide"* ]]
}

@test "Set-BackupDrive: rejects choice above maximum" {
    Get-ExternalDrives() {
        printf '%s\n' "sda1|500G|Backup|UUID-1|/mnt/backup"
    }
    printf '2\n' > "$TEST_DIR/input"
    run Set-BackupDrive < "$TEST_DIR/input"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Choix invalide"* ]]
}

@test "Set-BackupDrive: rejects negative choice" {
    Get-ExternalDrives() {
        printf '%s\n' "sda1|500G|Backup|UUID-1|/mnt/backup"
    }
    printf '%s\n' '-1' > "$TEST_DIR/input"
    run Set-BackupDrive < "$TEST_DIR/input"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Choix invalide"* ]]
}

@test "Set-BackupDrive: rejects decimal choice" {
    Get-ExternalDrives() {
        printf '%s\n' "sda1|500G|Backup|UUID-1|/mnt/backup"
    }
    printf '1.5\n' > "$TEST_DIR/input"
    run Set-BackupDrive < "$TEST_DIR/input"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Choix invalide"* ]]
}

@test "Set-BackupDrive: rejects EOF without choice" {
    Get-ExternalDrives() {
        printf '%s\n' "sda1|500G|Backup|UUID-1|/mnt/backup"
    }
    run Set-BackupDrive < /dev/null
    [ "$status" -eq 1 ]
    [[ "$output" == *"Choix invalide"* ]]
}

@test "Set-BackupDrive: uses Sans nom when drive label is empty" {
    Get-ExternalDrives() {
        printf '%s\n' "sda1|500G||UUID-1|/mnt/backup"
    }
    printf '1\n' > "$TEST_DIR/input"
    run Set-BackupDrive < "$TEST_DIR/input"
    [ "$status" -eq 0 ]
    [[ "$output" == *"1 - Sans nom (500G - /mnt/backup)"* ]]
    run jq -r '.backupDrive.name' "$CONFIG_FILE"
    [ "$output" = "Sans nom" ]
}

@test "Set-BackupDrive: rejects drive without UUID" {
    Get-ExternalDrives() {
        printf '%s\n' "sda1|500G|Backup||/mnt/backup"
    }
    printf '1\n' > "$TEST_DIR/input"
    run Set-BackupDrive < "$TEST_DIR/input"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Impossible de récupérer l'UUID"* ]]
}

@test "Set-BackupDrive: does not save when UUID is missing" {
    Get-ExternalDrives() {
        printf '%s\n' "sda1|500G|Backup||/mnt/backup"
    }
    Save-Config() {
        touch "$TEST_DIR/save-called"
        return 0
    }
    printf '1\n' > "$TEST_DIR/input"
    run Set-BackupDrive < "$TEST_DIR/input"
    [ "$status" -eq 1 ]
    [ ! -f "$TEST_DIR/save-called" ]
}

@test "Set-BackupDrive: reports Get-Config failure" {
    Get-Config() {
        return 1
    }
    run Set-BackupDrive
    [ "$status" -eq 1 ]
    [ "$output" = "failed" ]
}

@test "Set-BackupDrive: preserves existing configuration" {
    TEST_CONFIG='{
        "backupDrive": {
            "uuid": "OLD",
            "name": "Old Drive",
            "size": "100G"
        },
        "backupFolder": "MyBackup",
        "sources": [
            "/source/one"
        ],
        "language": "fr"
    }'
    printf '%s\n' "$TEST_CONFIG" > "$CONFIG_FILE"
    Get-ExternalDrives() {
        printf '%s\n' "sda1|500G|Backup|NEW|/mnt/backup"
    }
    printf '1\n' > "$TEST_DIR/input"
    run Set-BackupDrive < "$TEST_DIR/input"
    [ "$status" -eq 0 ]
    run jq -e '
        .backupDrive.uuid == "NEW" and
        .backupDrive.name == "Backup" and
        .backupDrive.size == "500G" and
        .backupFolder == "MyBackup" and
        .sources == ["/source/one"] and
        .language == "fr"
    ' "$CONFIG_FILE"
    [ "$status" -eq 0 ]
}


# ============================================================
# Set-BackupFolder
# ============================================================

@test "Set-BackupFolder: displays current folder" {
    TEST_CONFIG='{
        "backupDrive": {
            "uuid": "",
            "name": "",
            "size": ""
        },
        "backupFolder": "CurrentBackup",
        "sources": [],
        "language": "en"
    }'
    printf '%s\n' "$TEST_CONFIG" > "$CONFIG_FILE"
    printf 'NewBackup\n' > "$TEST_DIR/input"
    run Set-BackupFolder < "$TEST_DIR/input"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Dossier actuel : CurrentBackup"* ]]
}

@test "Set-BackupFolder: changes backup folder" {
    printf 'NewBackup\n' > "$TEST_DIR/input"
    run Set-BackupFolder < "$TEST_DIR/input"
    [ "$status" -eq 0 ]
    run jq -r '.backupFolder' "$CONFIG_FILE"
    [ "$output" = "NewBackup" ]
}

@test "Set-BackupFolder: keeps current folder when input is empty" {
    TEST_CONFIG='{
        "backupDrive": {
            "uuid": "",
            "name": "",
            "size": ""
        },
        "backupFolder": "CurrentBackup",
        "sources": [],
        "language": "en"
    }'
    printf '%s\n' "$TEST_CONFIG" > "$CONFIG_FILE"
    printf '\n' > "$TEST_DIR/input"
    run Set-BackupFolder < "$TEST_DIR/input"
    [ "$status" -eq 0 ]
    run jq -r '.backupFolder' "$CONFIG_FILE"
    [ "$output" = "CurrentBackup" ]
}

@test "Set-BackupFolder: keeps current folder when input is EOF" {
    TEST_CONFIG='{
        "backupDrive": {
            "uuid": "",
            "name": "",
            "size": ""
        },
        "backupFolder": "CurrentBackup",
        "sources": [],
        "language": "en"
    }'
    printf '%s\n' "$TEST_CONFIG" > "$CONFIG_FILE"
    run Set-BackupFolder < /dev/null
    [ "$status" -eq 0 ]
    run jq -r '.backupFolder' "$CONFIG_FILE"
    [ "$output" = "CurrentBackup" ]
}

@test "Set-BackupFolder: supports spaces in folder name" {
    printf '%s\n' 'My Backup Folder' > "$TEST_DIR/input"
    run Set-BackupFolder < "$TEST_DIR/input"
    [ "$status" -eq 0 ]
    run jq -r '.backupFolder' "$CONFIG_FILE"
    [ "$output" = "My Backup Folder" ]
}

@test "Set-BackupFolder: supports special characters" {
    printf '%s\n' 'Backup-éèà' > "$TEST_DIR/input"
    run Set-BackupFolder < "$TEST_DIR/input"
    [ "$status" -eq 0 ]
    run jq -r '.backupFolder' "$CONFIG_FILE"
    [ "$output" = "Backup-éèà" ]
}

@test "Set-BackupFolder: preserves other configuration values" {
    TEST_CONFIG='{
        "backupDrive": {
            "uuid": "UUID-1234",
            "name": "Backup Drive",
            "size": "1TB"
        },
        "backupFolder": "OldBackup",
        "sources": [
            "/source/one",
            "/source/two"
        ],
        "language": "fr"
    }'
    printf '%s\n' "$TEST_CONFIG" > "$CONFIG_FILE"
    printf 'NewBackup\n' > "$TEST_DIR/input"
    run Set-BackupFolder < "$TEST_DIR/input"
    [ "$status" -eq 0 ]
    run jq -e '
        .backupFolder == "NewBackup" and
        .backupDrive.uuid == "UUID-1234" and
        .backupDrive.name == "Backup Drive" and
        .backupDrive.size == "1TB" and
        .sources == ["/source/one", "/source/two"] and
        .language == "fr"
    ' "$CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "Set-BackupFolder: reports Get-Config failure" {
    Get-Config() {
        return 1
    }
    run Set-BackupFolder < /dev/null
    [ "$status" -eq 1 ]
    [ "$output" = "failed" ]
}

@test "Set-BackupFolder: reports Save-Config failure" {
    Save-Config() {
        return 1
    }
    printf 'NewBackup\n' > "$TEST_DIR/input"
    run Set-BackupFolder < "$TEST_DIR/input"
    [ "$status" -eq 1 ]
    [ "$output" = $'Dossier actuel : Backup\n\nfailed' ]
}

@test "Set-BackupFolder: saves valid JSON" {
    printf 'NewBackup\n' > "$TEST_DIR/input"
    run Set-BackupFolder < "$TEST_DIR/input"
    [ "$status" -eq 0 ]
    run jq empty "$CONFIG_FILE"
    [ "$status" -eq 0 ]
}


# ============================================================
# Integration
# ============================================================

@test "Set-BackupDrive then Set-BackupFolder preserves both settings" {
    Get-ExternalDrives() {
        printf '%s\n' "sda1|1T|Backup|UUID-1234|/mnt/backup"
    }
    printf '1\n' > "$TEST_DIR/drive-input"
    run Set-BackupDrive < "$TEST_DIR/drive-input"
    [ "$status" -eq 0 ]
    printf 'MyBackup\n' > "$TEST_DIR/folder-input"
    run Set-BackupFolder < "$TEST_DIR/folder-input"
    [ "$status" -eq 0 ]
    run jq -e '
        .backupDrive.uuid == "UUID-1234" and
        .backupDrive.name == "Backup" and
        .backupDrive.size == "1T" and
        .backupFolder == "MyBackup"
    ' "$CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "Set-BackupDrive saves valid JSON" {
    Get-ExternalDrives() {
        printf '%s\n' "sda1|500G|Backup|UUID-1234|/mnt/backup"
    }
    printf '1\n' > "$TEST_DIR/input"
    run Set-BackupDrive < "$TEST_DIR/input"
    [ "$status" -eq 0 ]
    run jq empty "$CONFIG_FILE"
    [ "$status" -eq 0 ]
}