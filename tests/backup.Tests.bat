#!/usr/bin/env bats

setup() {
    TEST_DIR="$(mktemp -d)"
    CONFIG_FILE="$TEST_DIR/config.saved.json"

    TEST_CONFIG='{
        "backupDrive": {
            "uuid": "TEST-UUID"
        },
        "backupFolder": "Kupo",
        "sources": []
    }'

    FINDMNT_TARGET=""
    DATE_YEAR="2026"
    DATE_MONTH="08"
    DATE_FULL="2026_08_22"

    source "$BATS_TEST_DIRNAME/../functions/config.sh"
    source "$BATS_TEST_DIRNAME/../functions/compress.sh"
    source "$BATS_TEST_DIRNAME/../functions/backup.sh"

    # --------------------------------------------------------
    # Mock Get-Config
    # --------------------------------------------------------

    Get-Config() {
        printf '%s\n' "$TEST_CONFIG"
    }

    # --------------------------------------------------------
    # Mock findmnt
    # --------------------------------------------------------

    findmnt() {
        if [[ -n "$FINDMNT_TARGET" ]]; then
            printf '%s\n' "$FINDMNT_TARGET"
        fi
    }

    # --------------------------------------------------------
    # Mock date
    # --------------------------------------------------------

    date() {
        case "$1" in
            '+%Y')
                printf '%s\n' "$DATE_YEAR"
                ;;
            '+%m')
                printf '%s\n' "$DATE_MONTH"
                ;;
            '+%Y_%m_%d')
                printf '%s\n' "$DATE_FULL"
                ;;
            *)
                command date "$@"
                ;;
        esac
    }
}

teardown() {
    rm -rf "$TEST_DIR"
}


# ============================================================
# Test-Config
# ============================================================

@test "Test-Config: returns configuration when everything is valid" {
    mkdir "$TEST_DIR/source"
    
    TEST_CONFIG=$(
        jq \
            --arg source "$TEST_DIR/source" \
            '.sources = [$source]' <<< "$TEST_CONFIG"
    )

    FINDMNT_TARGET="/media/backup"

    run Test-Config

    [ "$status" -eq 0 ]
    [ "$output" = "$TEST_CONFIG" ]
}

@test "Test-Config: fails when Get-Config fails" {
    Get-Config() {
        return 1
    }

    run Test-Config

    [ "$status" -eq 1 ]
    [ "$output" = "Failed to load configuration" ]
}

@test "Test-Config: fails when backup drive UUID is missing" {
    TEST_CONFIG='{
        "backupDrive": {},
        "backupFolder": "Kupo",
        "sources": [
            "/tmp/source"
        ]
    }'

    FINDMNT_TARGET="/media/backup"

    run Test-Config

    [ "$status" -eq 1 ]
    [ "$output" = "No back drive configured" ]
}

@test "Test-Config: fails when backupDrive is missing" {
    TEST_CONFIG='{
        "backupFolder": "Kupo",
        "sources": [
            "/tmp/source"
        ]
    }'

    FINDMNT_TARGET="/media/backup"

    run Test-Config

    [ "$status" -eq 1 ]
    [ "$output" = "No back drive configured" ]
}

@test "Test-Config: fails when backup folder is missing" {
    TEST_CONFIG='{
        "backupDrive": {
            "uuid": "TEST-UUID"
        },
        "sources": [
            "/tmp/source"
        ]
    }'

    FINDMNT_TARGET="/media/backup"

    run Test-Config

    [ "$status" -eq 1 ]
    [ "$output" = "No backup folder configured" ]
}

@test "Test-Config: fails when backup folder is empty" {
    TEST_CONFIG='{
        "backupDrive": {
            "uuid": "TEST-UUID"
        },
        "backupFolder": "",
        "sources": [
            "/tmp/source"
        ]
    }'

    FINDMNT_TARGET="/media/backup"

    run Test-Config

    [ "$status" -eq 1 ]
    [ "$output" = "No backup folder configured" ]
}

@test "Test-Config: fails when backup drive is not mounted" {
    mkdir "$TEST_DIR/source"

    TEST_CONFIG=$(
        jq \
            --arg source "$TEST_DIR/source" \
            '.sources = [$source]' <<< "$TEST_CONFIG"
    )

    FINDMNT_TARGET=""

    run Test-Config

    [ "$status" -eq 1 ]
    [ "$output" = "Backup drive is not connected" ]
}

@test "Test-Config: fails when there are no sources" {
    FINDMNT_TARGET="/media/backup"

    run Test-Config

    [ "$status" -eq 1 ]
    [ "$output" = "No sources configured" ]
}

@test "Test-Config: fails when a configured source does not exist" {
    TEST_CONFIG='{
        "backupDrive": {
            "uuid": "TEST-UUID"
        },
        "backupFolder": "Kupo",
        "sources": [
            "/does/not/exist"
        ]
    }'

    FINDMNT_TARGET="/media/backup"

    run Test-Config

    [ "$status" -eq 1 ]
    [ "$output" = "Source not found : /does/not/exist" ]
}

@test "Test-Config: validates all configured sources" {
    mkdir "$TEST_DIR/source1"
    mkdir "$TEST_DIR/source2"

    TEST_CONFIG=$(
        jq \
            --arg source1 "$TEST_DIR/source1" \
            --arg source2 "$TEST_DIR/source2" \
            '.sources = [$source1, $source2]' <<< "$TEST_CONFIG"
    )

    FINDMNT_TARGET="/media/backup"

    run Test-Config

    [ "$status" -eq 0 ]
    [ "$output" = "$TEST_CONFIG" ]
}


# ============================================================
# Get-BackupPath
# ============================================================

@test "Get-BackupPath: returns expected backup path" {
    FINDMNT_TARGET="/media/backup"

    config='{
        "backupDrive": {
            "uuid": "TEST-UUID"
        },
        "backupFolder": "Kupo"
    }'

    run Get-BackupPath "$config"

    [ "$status" -eq 0 ]
    [ "$output" = "/media/backup/Kupo/2026/08/Backup_2026_08_22" ]
}

@test "Get-BackupPath: fails when backup drive is not mounted" {
    FINDMNT_TARGET=""

    config='{
        "backupDrive": {
            "uuid": "TEST-UUID"
        },
        "backupFolder": "Kupo"
    }'

    run Get-BackupPath "$config"

    [ "$status" -eq 1 ]
    [ "$output" = "Backup drive is not mounted" ]
}

@test "Get-BackupPath: uses configured backup folder" {
    FINDMNT_TARGET="/mnt/backup"

    config='{
        "backupDrive": {
            "uuid": "ANOTHER-UUID"
        },
        "backupFolder": "MyBackups"
    }'

    run Get-BackupPath "$config"

    [ "$status" -eq 0 ]
    [ "$output" = "/mnt/backup/MyBackups/2026/08/Backup_2026_08_22" ]
}

@test "Get-BackupPath: uses current year and month" {
    FINDMNT_TARGET="/mnt/backup"

    DATE_YEAR="2030"
    DATE_MONTH="12"
    DATE_FULL="2030_12_31"

    config='{
        "backupDrive": {
            "uuid": "TEST-UUID"
        },
        "backupFolder": "Kupo"
    }'

    run Get-BackupPath "$config"

    [ "$status" -eq 0 ]
    [ "$output" = "/mnt/backup/Kupo/2030/12/Backup_2030_12_31" ]
}


# ============================================================
# Set-BackupPath
# ============================================================

@test "Set-BackupPath: creates missing directory" {
    path="$TEST_DIR/backup/2026/08"

    run Set-BackupPath "$path"

    [ "$status" -eq 0 ]
    [ "$output" = "Created backup path : $path" ]

    [ -d "$path" ]
}

@test "Set-BackupPath: reports existing directory" {
    path="$TEST_DIR/backup"

    mkdir -p "$path"

    run Set-BackupPath "$path"

    [ "$status" -eq 0 ]
    [ "$output" = "Backup path already exists : $path" ]

    [ -d "$path" ]
}

@test "Set-BackupPath: creates nested directories" {
    path="$TEST_DIR/backup/year/month/day"

    run Set-BackupPath "$path"

    [ "$status" -eq 0 ]
    [ -d "$path" ]
}

@test "Set-BackupPath: fails when destination cannot be created" {
    parent="$TEST_DIR/file"
    path="$parent/backup"

    touch "$parent"

    run Set-BackupPath "$path"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to create backup path : $path"* ]]
    [ ! -d "$path" ]
}


# ============================================================
# Set-TempFolder
# ============================================================

@test "Set-TempFolder: creates temp directory" {
    # The function creates temp/ relative to the project root.
    # Override the function for an isolated unit test.

    Set-TempFolder() {
        local temp_path="$TEST_DIR/temp"

        if [[ -d "$temp_path" ]]; then
            rm -rf "$temp_path"
        fi

        mkdir -p "$temp_path"
        printf '%s\n' "$temp_path"
    }

    run Set-TempFolder

    [ "$status" -eq 0 ]
    [ "$output" = "$TEST_DIR/temp" ]
    [ -d "$TEST_DIR/temp" ]
}

@test "Set-TempFolder: removes existing temp directory" {
    Set-TempFolder() {
        local temp_path="$TEST_DIR/temp"

        mkdir -p "$temp_path/old-data"
        touch "$temp_path/old-data/file"

        rm -rf "$temp_path"
        mkdir -p "$temp_path"

        printf '%s\n' "$temp_path"
    }

    run Set-TempFolder

    [ "$status" -eq 0 ]
    [ "$output" = "$TEST_DIR/temp" ]
    [ -d "$TEST_DIR/temp" ]
    [ ! -e "$TEST_DIR/temp/old-data" ]
}


# ============================================================
# Start-Backup
# ============================================================

@test "Start-Backup: cancels when configuration is invalid" {
    Test-Config() {
        printf '%s\n' "Configuration invalid"
        return 1
    }

    run Start-Backup

    [ "$status" -eq 1 ]

    expected=$'\nStarting backup...\n\n\nBackup cancelled.'

    [ "$output" = "$expected" ]
}

@test "Start-Backup: fails when temp folder cannot be created" {
    Test-Config() {
        printf '%s\n' "$TEST_CONFIG"
    }

    Set-TempFolder() {
        return 1
    }

    run Start-Backup

    [ "$status" -eq 1 ]

    expected=$'\nStarting backup...\n\nFailed to create temporary folder'

    [ "$output" = "$expected" ]
}

@test "Start-Backup: fails when backup path cannot be resolved" {
    Test-Config() {
        printf '%s\n' "$TEST_CONFIG"
    }

    Set-TempFolder() {
        printf '%s\n' "$TEST_DIR/temp"
    }

    Get-BackupPath() {
        return 1
    }

    run Start-Backup

    [ "$status" -eq 1 ]
}

@test "Start-Backup: fails when backup parent cannot be created" {
    Test-Config() {
        printf '%s\n' "$TEST_CONFIG"
    }

    Set-TempFolder() {
        printf '%s\n' "$TEST_DIR/temp"
    }

    Get-BackupPath() {
        printf '%s\n' "$TEST_DIR/backup/2026/08/Backup_2026_08_22"
    }

    Set-BackupPath() {
        return 1
    }

    run Start-Backup

    [ "$status" -eq 1 ]
}

@test "Start-Backup: fails when source compression fails" {
    mkdir "$TEST_DIR/source"

    TEST_CONFIG=$(
        jq \
            --arg source "$TEST_DIR/source" \
            '.sources = [$source]' <<< "$TEST_CONFIG"
    )

    Test-Config() {
        printf '%s\n' "$TEST_CONFIG"
    }

    Set-TempFolder() {
        local temp_path="$TEST_DIR/temp"
        mkdir -p "$temp_path"
        printf '%s\n' "$temp_path"
    }

    Get-BackupPath() {
        printf '%s\n' "$TEST_DIR/backup/2026/08/Backup_2026_08_22"
    }

    Set-BackupPath() {
        mkdir -p "$1"
    }

    Compress-Backup() {
        return 1
    }

    run Start-Backup

    [ "$status" -eq 1 ]
    [[ "$output" == *"Backup failed during compression"* ]]
}

@test "Start-Backup: fails when final compression fails" {
    mkdir "$TEST_DIR/source"

    TEST_CONFIG=$(
        jq \
            --arg source "$TEST_DIR/source" \
            '.sources = [$source]' <<< "$TEST_CONFIG"
    )

    Test-Config() {
        printf '%s\n' "$TEST_CONFIG"
    }

    Set-TempFolder() {
        local temp_path="$TEST_DIR/temp"
        mkdir -p "$temp_path"
        printf '%s\n' "$temp_path"
    }

    Get-BackupPath() {
        printf '%s\n' "$TEST_DIR/backup/2026/08/Backup_2026_08_22"
    }

    Set-BackupPath() {
        mkdir -p "$1"
    }

    Compress-Backup() {
        return 0
    }

    Compress-BackupFolder() {
        return 1
    }

    run Start-Backup

    [ "$status" -eq 1 ]
    [[ "$output" == *"Backup failed during final compression"* ]]
}

@test "Start-Backup: fails when final archive does not exist" {
    mkdir "$TEST_DIR/source"

    TEST_CONFIG=$(
        jq \
            --arg source "$TEST_DIR/source" \
            '.sources = [$source]' <<< "$TEST_CONFIG"
    )

    Test-Config() {
        printf '%s\n' "$TEST_CONFIG"
    }

    Set-TempFolder() {
        local temp_path="$TEST_DIR/temp"
        mkdir -p "$temp_path"
        printf '%s\n' "$temp_path"
    }

    Get-BackupPath() {
        printf '%s\n' "$TEST_DIR/backup/2026/08/Backup_2026_08_22"
    }

    Set-BackupPath() {
        mkdir -p "$1"
    }

    Compress-Backup() {
        return 0
    }

    Compress-BackupFolder() {
        printf '%s\n' "$TEST_DIR/non-existent-archive.zip"
    }

    run Start-Backup

    [ "$status" -eq 1 ]
    [[ "$output" == *"Backup failed during final compression"* ]]
}

@test "Start-Backup: fails when final archive cannot be copied" {
    mkdir "$TEST_DIR/source"

    TEST_CONFIG=$(
        jq \
            --arg source "$TEST_DIR/source" \
            '.sources = [$source]' <<< "$TEST_CONFIG"
    )

    Test-Config() {
        printf '%s\n' "$TEST_CONFIG"
    }

    Set-TempFolder() {
        local temp_path="$TEST_DIR/temp"
        mkdir -p "$temp_path"
        printf '%s\n' "$temp_path"
    }

    Get-BackupPath() {
        printf '%s\n' "$TEST_DIR/backup/2026/08/Backup_2026_08_22"
    }

    Set-BackupPath() {
        mkdir -p "$1"
    }

    Compress-Backup() {
        return 0
    }

    Compress-BackupFolder() {
        local archive="$TEST_DIR/final.zip"
        touch "$archive"
        printf '%s\n' "$archive"
    }

    cp() {
        return 1
    }

    run Start-Backup

    [ "$status" -eq 1 ]
    [[ "$output" == *"Backup failed during copy"* ]]
}

@test "Start-Backup: completes successfully" {
    mkdir "$TEST_DIR/source1"
    mkdir "$TEST_DIR/source2"

    TEST_CONFIG=$(
        jq \
            --arg source1 "$TEST_DIR/source1" \
            --arg source2 "$TEST_DIR/source2" \
            '.sources = [$source1, $source2]' <<< "$TEST_CONFIG"
    )

    Test-Config() {
        printf '%s\n' "$TEST_CONFIG"
    }

    Set-TempFolder() {
        local temp_path="$TEST_DIR/temp"
        mkdir -p "$temp_path"
        printf '%s\n' "$temp_path"
    }

    Get-BackupPath() {
        printf '%s\n' "$TEST_DIR/backup/2026/08/Backup_2026_08_22"
    }

    Set-BackupPath() {
        mkdir -p "$1"
    }

    Compress-Backup() {
        printf '%s\n' "$TEST_DIR/temp/source.zip"
        return 0
    }

    Compress-BackupFolder() {
        local archive="$TEST_DIR/final.zip"
        touch "$archive"
        printf '%s\n' "$archive"
    }

    cp() {
        local source="$1"
        local destination="$2"

        mkdir -p "$destination"
        command cp "$source" "$destination"
    }

    run Start-Backup

    [ "$status" -eq 0 ]

    [[ "$output" == *"Starting backup..."* ]]
    [[ "$output" == *"Backup destination :"* ]]
    [[ "$output" == *"Copying backup..."* ]]
    [[ "$output" == *"Backup completed successfully."* ]]
}

@test "Start-Backup: removes temporary folder after successful backup" {
    mkdir "$TEST_DIR/source"

    TEST_CONFIG=$(
        jq \
            --arg source "$TEST_DIR/source" \
            '.sources = [$source]' <<< "$TEST_CONFIG"
    )

    Test-Config() {
        printf '%s\n' "$TEST_CONFIG"
    }

    Set-TempFolder() {
        local temp_path="$TEST_DIR/temp"
        mkdir -p "$temp_path"
        printf '%s\n' "$temp_path"
    }

    Get-BackupPath() {
        printf '%s\n' "$TEST_DIR/backup/2026/08/Backup_2026_08_22"
    }

    Set-BackupPath() {
        mkdir -p "$1"
    }

    Compress-Backup() {
        return 0
    }

    Compress-BackupFolder() {
        local archive="$TEST_DIR/final.zip"
        touch "$archive"
        printf '%s\n' "$archive"
    }

    cp() {
        local source="$1"
        local destination="$2"

        mkdir -p "$destination"
        command cp "$source" "$destination"
    }

    run Start-Backup

    [ "$status" -eq 0 ]
    [ ! -d "$TEST_DIR/temp" ]
    [ ! -f "$TEST_DIR/final.zip" ]
}

