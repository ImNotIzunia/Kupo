#!/usr/bin/env bats

setup() {
    TEST_DIR="$(mktemp -d)"

    SOURCE_DIR="$TEST_DIR/source"
    DESTINATION_DIR="$TEST_DIR/destination"

    mkdir -p "$SOURCE_DIR"
    mkdir -p "$DESTINATION_DIR"

    source "$BATS_TEST_DIRNAME/../functions/compress.sh"

    # Stand-ins for helpers normally provided by other Kupo modules
    # (logging.sh / i18n.sh / progress.sh) that aren't part of this
    # test target. Swap these out for the real modules if/when they're
    # sourced here instead.
    Write-Log() { :; }

    Get-String() {
        case "$1" in
            compress.compress)       echo "Compressing" ;;
            compress.sucess)         echo "Compression completed" ;;
            compress.failed)         echo "Failed to compress" ;;
            compress.nosource)       echo "Source not found" ;;
            compress.nosources)      echo "No sources to compress" ;;
            compress.backupfailed)   echo "Backup compression failed" ;;
            compress.backupsucess)   echo "All sources compressed" ;;
            compress.foldernotfound) echo "Source folder not found" ;;
            compress.foldercreate)   echo "Creating final backup archive..." ;;
            compress.folderfailed)   echo "Failed to create final backup archive" ;;
            compress.foldersuccess)  echo "Final compression completed" ;;
            *)                       echo "$1" ;;
        esac
    }

    Show-ProgressBar() { :; }
}

teardown() {
    rm -rf "$TEST_DIR"
}


# ============================================================
# Compress-Source
# ============================================================

@test "Compress-Source: compresses a valid directory" {
    mkdir "$SOURCE_DIR/project"
    printf '%s\n' "hello" > "$SOURCE_DIR/project/file.txt"

    run Compress-Source \
        "$SOURCE_DIR/project" \
        "$DESTINATION_DIR"

    [ "$status" -eq 0 ]

    [[ "$output" == *"Compressing : project"* ]]
    [[ "$output" == *"Compression completed : project.zip"* ]]
    [[ "$output" == *"$DESTINATION_DIR/project.zip"* ]]

    [ -f "$DESTINATION_DIR/project.zip" ]
}

@test "Compress-Source: creates destination directory when missing" {
    mkdir "$SOURCE_DIR/project"
    printf '%s\n' "hello" > "$SOURCE_DIR/project/file.txt"

    destination="$TEST_DIR/new-destination"

    run Compress-Source \
        "$SOURCE_DIR/project" \
        "$destination"

    [ "$status" -eq 0 ]
    [ -d "$destination" ]
    [ -f "$destination/project.zip" ]
}

@test "Compress-Source: rejects missing source" {
    source="$TEST_DIR/does-not-exist"

    run Compress-Source \
        "$source" \
        "$DESTINATION_DIR"

    [ "$status" -eq 1 ]
    [ "$output" = "Source not found : $source" ]

    [ ! -f "$DESTINATION_DIR/does-not-exist.zip" ]
}

@test "Compress-Source: compresses files inside source directory" {
    mkdir "$SOURCE_DIR/project"

    printf '%s\n' "file one" > "$SOURCE_DIR/project/file1.txt"
    printf '%s\n' "file two" > "$SOURCE_DIR/project/file2.txt"

    run Compress-Source \
        "$SOURCE_DIR/project" \
        "$DESTINATION_DIR"

    [ "$status" -eq 0 ]
    [ -f "$DESTINATION_DIR/project.zip" ]

    run unzip -l "$DESTINATION_DIR/project.zip"

    [ "$status" -eq 0 ]
    [[ "$output" == *"project/file1.txt"* ]]
    [[ "$output" == *"project/file2.txt"* ]]
}

@test "Compress-Source: preserves source directory name" {
    mkdir "$SOURCE_DIR/my-project"

    run Compress-Source \
        "$SOURCE_DIR/my-project" \
        "$DESTINATION_DIR"

    [ "$status" -eq 0 ]
    [ -f "$DESTINATION_DIR/my-project.zip" ]
    [ ! -f "$DESTINATION_DIR/source.zip" ]
}

@test "Compress-Source: works with spaces in source path" {
    source="$TEST_DIR/my project"
    mkdir -p "$source"

    printf '%s\n' "hello" > "$source/file.txt"

    run Compress-Source \
        "$source" \
        "$DESTINATION_DIR"

    [ "$status" -eq 0 ]
    [ -f "$DESTINATION_DIR/my project.zip" ]
}

@test "Compress-Source: works with spaces in destination path" {
    destination="$TEST_DIR/my destination"

    mkdir "$SOURCE_DIR/project"
    mkdir -p "$destination"

    printf '%s\n' "hello" > "$SOURCE_DIR/project/file.txt"

    run Compress-Source \
        "$SOURCE_DIR/project" \
        "$destination"

    [ "$status" -eq 0 ]
    [ -f "$destination/project.zip" ]
}

@test "Compress-Source: returns archive path on stdout" {
    mkdir "$SOURCE_DIR/project"

    run Compress-Source \
        "$SOURCE_DIR/project" \
        "$DESTINATION_DIR"

    [ "$status" -eq 0 ]
    [[ "$output" == *"$DESTINATION_DIR/project.zip" ]]
}

@test "Compress-Source: does not overwrite source directory" {
    mkdir "$SOURCE_DIR/project"
    printf '%s\n' "important" > "$SOURCE_DIR/project/file.txt"

    run Compress-Source \
        "$SOURCE_DIR/project" \
        "$DESTINATION_DIR"

    [ "$status" -eq 0 ]
    [ -d "$SOURCE_DIR/project" ]
    [ -f "$SOURCE_DIR/project/file.txt" ]
}

@test "Compress-Source: reports zip failure" {
    mkdir "$SOURCE_DIR/project"

    zip() {
        return 1
    }

    run Compress-Source \
        "$SOURCE_DIR/project" \
        "$DESTINATION_DIR"

    [ "$status" -eq 1 ]
    [ "$output" = "Compressing : project
Failed to compress : $SOURCE_DIR/project" ]
}


# ============================================================
# Compress-Backup
# ============================================================

@test "Compress-Backup: rejects empty source list" {
    run Compress-Backup "$DESTINATION_DIR"

    [ "$status" -eq 1 ]
    [ "$output" = "No sources to compress" ]
}

@test "Compress-Backup: compresses one source" {
    mkdir "$SOURCE_DIR/project"
    printf '%s\n' "hello" > "$SOURCE_DIR/project/file.txt"

    run Compress-Backup \
        "$DESTINATION_DIR" \
        "$SOURCE_DIR/project"

    [ "$status" -eq 0 ]

    [[ "$output" == *"[1/1] Compressing : project"* ]]
    [[ "$output" == *"All sources compressed"* ]]

    [ -f "$DESTINATION_DIR/project.zip" ]
}

@test "Compress-Backup: compresses multiple sources" {
    mkdir "$SOURCE_DIR/project1"
    mkdir "$SOURCE_DIR/project2"
    mkdir "$SOURCE_DIR/project3"

    printf '%s\n' "one" > "$SOURCE_DIR/project1/file.txt"
    printf '%s\n' "two" > "$SOURCE_DIR/project2/file.txt"
    printf '%s\n' "three" > "$SOURCE_DIR/project3/file.txt"

    run Compress-Backup \
        "$DESTINATION_DIR" \
        "$SOURCE_DIR/project1" \
        "$SOURCE_DIR/project2" \
        "$SOURCE_DIR/project3"

    [ "$status" -eq 0 ]

    [[ "$output" == *"[1/3] Compressing : project1"* ]]
    [[ "$output" == *"[2/3] Compressing : project2"* ]]
    [[ "$output" == *"[3/3] Compressing : project3"* ]]
    [[ "$output" == *"All sources compressed"* ]]

    [ -f "$DESTINATION_DIR/project1.zip" ]
    [ -f "$DESTINATION_DIR/project2.zip" ]
    [ -f "$DESTINATION_DIR/project3.zip" ]
}

@test "Compress-Backup: preserves source order" {
    mkdir "$SOURCE_DIR/alpha"
    mkdir "$SOURCE_DIR/beta"
    mkdir "$SOURCE_DIR/gamma"

    run Compress-Backup \
        "$DESTINATION_DIR" \
        "$SOURCE_DIR/alpha" \
        "$SOURCE_DIR/beta" \
        "$SOURCE_DIR/gamma"

    [ "$status" -eq 0 ]

    alpha_pos=$(grep -nF "[1/3] Compressing : alpha" <<< "$output" | cut -d: -f1)
    beta_pos=$(grep -nF "[2/3] Compressing : beta" <<< "$output" | cut -d: -f1)
    gamma_pos=$(grep -nF "[3/3] Compressing : gamma" <<< "$output" | cut -d: -f1)

    [ "$alpha_pos" -lt "$beta_pos" ]
    [ "$beta_pos" -lt "$gamma_pos" ]

    [[ "$output" == *"All sources compressed"* ]]
}

@test "Compress-Backup: stops when source compression fails" {
    mkdir "$SOURCE_DIR/project1"
    mkdir "$SOURCE_DIR/project2"

    Compress-Source() {
        local source="$1"

        if [[ "$source" == "$SOURCE_DIR/project2" ]]; then
            return 1
        fi

        echo "Compressing : project1"
        echo "Compression completed : project1.zip"
        return 0
    }

    run Compress-Backup \
        "$DESTINATION_DIR" \
        "$SOURCE_DIR/project1" \
        "$SOURCE_DIR/project2"

    [ "$status" -eq 1 ]

    [[ "$output" == *"[1/2] Compressing : project1"* ]]
    [[ "$output" == *"[2/2] Compressing : project2"* ]]
    [[ "$output" == *"Backup compression failed"* ]]
}

@test "Compress-Backup: does not process sources after failure" {
    mkdir "$SOURCE_DIR/project1"
    mkdir "$SOURCE_DIR/project2"
    mkdir "$SOURCE_DIR/project3"

    Compress-Source() {
        local source="$1"

        if [[ "$source" == "$SOURCE_DIR/project1" ]]; then
            touch "$TEST_DIR/project1.called"
            return 0
        fi

        if [[ "$source" == "$SOURCE_DIR/project2" ]]; then
            touch "$TEST_DIR/project2.called"
            return 1
        fi

        if [[ "$source" == "$SOURCE_DIR/project3" ]]; then
            touch "$TEST_DIR/project3.called"
            return 0
        fi
    }

    run Compress-Backup \
        "$DESTINATION_DIR" \
        "$SOURCE_DIR/project1" \
        "$SOURCE_DIR/project2" \
        "$SOURCE_DIR/project3"

    [ "$status" -eq 1 ]

    [ -f "$TEST_DIR/project1.called" ]
    [ -f "$TEST_DIR/project2.called" ]
    [ ! -f "$TEST_DIR/project3.called" ]

    [[ "$output" == *"[1/3] Compressing : project1"* ]]
    [[ "$output" == *"[2/3] Compressing : project2"* ]]
    [[ "$output" != *"[3/3] Compressing : project3"* ]]

    [[ "$output" == *"Backup compression failed"* ]]
}

@test "Compress-Backup: propagates compression failure status" {
    mkdir "$SOURCE_DIR/project"

    Compress-Source() {
        return 1
    }

    run Compress-Backup \
        "$DESTINATION_DIR" \
        "$SOURCE_DIR/project"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Backup compression failed"* ]]
}


# ============================================================
# Compress-BackupFolder
# ============================================================

@test "Compress-BackupFolder: compresses a valid folder" {
    source_folder="$TEST_DIR/temp"
    mkdir -p "$source_folder"

    printf '%s\n' "hello" > "$source_folder/file.txt"

    run Compress-BackupFolder \
        "$source_folder" \
        "$DESTINATION_DIR" \
        "Backup_2026_08_22"

    [ "$status" -eq 0 ]

    [ -f "$DESTINATION_DIR/Backup_2026_08_22.zip" ]

    [[ "$output" == *"Creating final backup archive..."* ]]
    [[ "$output" == *"Final compression completed : Backup_2026_08_22.zip"* ]]
    [[ "$output" == *"$DESTINATION_DIR/Backup_2026_08_22.zip"* ]]
}

@test "Compress-BackupFolder: rejects missing source folder" {
    source_folder="$TEST_DIR/missing"

    run Compress-BackupFolder \
        "$source_folder" \
        "$DESTINATION_DIR" \
        "Backup"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Source folder not found : $source_folder"* ]]

    [ ! -f "$DESTINATION_DIR/Backup.zip" ]
}

@test "Compress-BackupFolder: creates missing destination directory" {
    source_folder="$TEST_DIR/temp"
    destination="$TEST_DIR/new-destination"

    mkdir -p "$source_folder"
    printf '%s\n' "hello" > "$source_folder/file.txt"

    run Compress-BackupFolder \
        "$source_folder" \
        "$destination" \
        "Backup"

    [ "$status" -eq 0 ]

    [ -d "$destination" ]
    [ -f "$destination/Backup.zip" ]
}

@test "Compress-BackupFolder: preserves files in archive" {
    source_folder="$TEST_DIR/temp"

    mkdir -p "$source_folder/subdir"

    printf '%s\n' "root" > "$source_folder/root.txt"
    printf '%s\n' "nested" > "$source_folder/subdir/nested.txt"

    run Compress-BackupFolder \
        "$source_folder" \
        "$DESTINATION_DIR" \
        "Backup"

    [ "$status" -eq 0 ]

    run unzip -l "$DESTINATION_DIR/Backup.zip"

    [ "$status" -eq 0 ]

    [[ "$output" == *"root.txt"* ]]
    [[ "$output" == *"subdir/nested.txt"* ]]
}

@test "Compress-BackupFolder: does not include parent directory name" {
    source_folder="$TEST_DIR/temp"

    mkdir -p "$source_folder"
    printf '%s\n' "hello" > "$source_folder/file.txt"

    run Compress-BackupFolder \
        "$source_folder" \
        "$DESTINATION_DIR" \
        "Backup"

    [ "$status" -eq 0 ]

    run unzip -l "$DESTINATION_DIR/Backup.zip"

    [ "$status" -eq 0 ]

    [[ "$output" == *"file.txt"* ]]
    [[ "$output" != *"temp/file.txt"* ]]
}

@test "Compress-BackupFolder: returns archive path on stdout" {
    source_folder="$TEST_DIR/temp"

    mkdir -p "$source_folder"

    printf '%s\n' "hello" > "$source_folder/file.txt"

    run Compress-BackupFolder \
        "$source_folder" \
        "$DESTINATION_DIR" \
        "Backup"

    [ "$status" -eq 0 ]

    [ -f "$DESTINATION_DIR/Backup.zip" ]

    [[ "$output" == *"$DESTINATION_DIR/Backup.zip" ]]
}

@test "Compress-BackupFolder: reports zip failure" {
    source_folder="$TEST_DIR/temp"
    mkdir -p "$source_folder"

    zip() {
        return 1
    }

    run Compress-BackupFolder \
        "$source_folder" \
        "$DESTINATION_DIR" \
        "Backup"

    [ "$status" -eq 1 ]

    [[ "$output" == *"Failed to create final backup archive"* ]]
}

@test "Compress-BackupFolder: works with spaces in paths" {
    source_folder="$TEST_DIR/my temp folder"
    destination="$TEST_DIR/my destination"

    mkdir -p "$source_folder"
    mkdir -p "$destination"

    printf '%s\n' "hello" > "$source_folder/file.txt"

    run Compress-BackupFolder \
        "$source_folder" \
        "$destination" \
        "My Backup"

    [ "$status" -eq 0 ]

    [ -f "$destination/My Backup.zip" ]
}

@test "Compress-BackupFolder: does not modify source folder" {
    source_folder="$TEST_DIR/temp"

    mkdir -p "$source_folder"
    printf '%s\n' "important" > "$source_folder/file.txt"

    run Compress-BackupFolder \
        "$source_folder" \
        "$DESTINATION_DIR" \
        "Backup"

    [ "$status" -eq 0 ]

    [ -d "$source_folder" ]
    [ -f "$source_folder/file.txt" ]

    [ "$(cat "$source_folder/file.txt")" = "important" ]
}

