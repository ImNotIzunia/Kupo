#!/usr/bin/env bats

setup() {
    TEST_DIR="$(mktemp -d)"

    CONFIG_DIR="$TEST_DIR/config"
    CONFIG_FILE="$CONFIG_DIR/config.json"

    mkdir -p "$CONFIG_DIR"

    source "$BATS_TEST_DIRNAME/../functions/config.sh"

    Get-Config-Path() {
        printf '%s\n' "$CONFIG_FILE"
    }
}

teardown() {
    rm -rf "$TEST_DIR"
}


# ============================================================
# Get-Config-Path
# ============================================================

@test "Get-Config-Path: returns configured config path" {
    run Get-Config-Path

    [ "$status" -eq 0 ]
    [ "$output" = "$CONFIG_FILE" ]
}

@test "Get-Config-Path: returns a path ending with config.json" {
    run Get-Config-Path

    [ "$status" -eq 0 ]
    [[ "$output" == */config.json ]]
}


# ============================================================
# Get-Config
# ============================================================

@test "Get-Config: creates default configuration when file does not exist" {
    run Get-Config

    [ "$status" -eq 0 ]
    [ -f "$CONFIG_FILE" ]

    run jq -e '.' "$CONFIG_FILE"

    [ "$status" -eq 0 ]
}

@test "Get-Config: creates expected default configuration" {
    run Get-Config

    [ "$status" -eq 0 ]

    run jq -e '
        .backupDrive.uuid == "" and
        .backupDrive.name == "" and
        .backupDrive.size == "" and
        .backupFolder == "Backup" and
        .sources == [] and
        .language == "en"
    ' <<< "$output"

    [ "$status" -eq 0 ]
}

@test "Get-Config: saves default configuration to disk" {
    run Get-Config

    [ "$status" -eq 0 ]
    [ -f "$CONFIG_FILE" ]

    run jq -e '
        .backupDrive.uuid == "" and
        .backupDrive.name == "" and
        .backupDrive.size == "" and
        .backupFolder == "Backup" and
        .sources == [] and
        .language == "en"
    ' "$CONFIG_FILE"

    [ "$status" -eq 0 ]
}

@test "Get-Config: returns existing valid configuration" {
    cat > "$CONFIG_FILE" <<'EOF'
{
    "backupDrive": {
        "uuid": "1234",
        "name": "Backup Drive",
        "size": "1TB"
    },
    "backupFolder": "MyBackup",
    "sources": [
        "/tmp/source1"
    ],
    "language": "fr"
}
EOF

    run Get-Config

    [ "$status" -eq 0 ]

    run jq -S '.' <<< "$output"

    [ "$status" -eq 0 ]
    [[ "$output" == *'"uuid": "1234"'* ]]
    [[ "$output" == *'"backupFolder": "MyBackup"'* ]]
    [[ "$output" == *'"/tmp/source1"'* ]]
    [[ "$output" == *'"language": "fr"'* ]]
}

@test "Get-Config: preserves existing configuration" {
    original='{
        "backupDrive": {
            "uuid": "abcd",
            "name": "Drive",
            "size": "500GB"
        },
        "backupFolder": "Backup",
        "sources": [
            "/source/one",
            "/source/two"
        ],
        "language": "en"
    }'

    printf '%s\n' "$original" > "$CONFIG_FILE"

    run Get-Config

    [ "$status" -eq 0 ]

    run jq -S '.' <<< "$output"
    [ "$status" -eq 0 ]

    run jq -S '.' "$CONFIG_FILE"

    [ "$status" -eq 0 ]
    [ "$output" = "$(jq -S '.' <<< "$original")" ]
}

@test "Get-Config: rejects invalid JSON" {
    printf '%s\n' '{ invalid json' > "$CONFIG_FILE"

    run Get-Config

    [ "$status" -eq 1 ]
    [ "$output" = "failed" ]
}

@test "Get-Config: rejects empty configuration file" {
    : > "$CONFIG_FILE"

    run Get-Config

    [ "$status" -eq 1 ]
    [ "$output" = "failed" ]
}

@test "Get-Config: accepts valid empty JSON object" {
    printf '%s\n' '{}' > "$CONFIG_FILE"

    run Get-Config

    [ "$status" -eq 0 ]
    [ "$output" = "{}" ]
}

@test "Get-Config: accepts valid JSON array" {
    printf '%s\n' '[]' > "$CONFIG_FILE"

    run Get-Config

    [ "$status" -eq 0 ]
    [ "$output" = "[]" ]
}


# ============================================================
# Save-Config
# ============================================================

@test "Save-Config: saves valid configuration" {
    config='{
        "backupDrive": {
            "uuid": "1234",
            "name": "Backup",
            "size": "1TB"
        },
        "backupFolder": "Backup",
        "sources": [],
        "language": "en"
    }'

    run Save-Config "$config"

    [ "$status" -eq 0 ]
    [ "$output" = "success save" ]

    [ -f "$CONFIG_FILE" ]

    run jq -e '.' "$CONFIG_FILE"

    [ "$status" -eq 0 ]
}

@test "Save-Config: saves valid JSON with formatting" {
    config='{"name":"test","value":123}'

    run Save-Config "$config"

    [ "$status" -eq 0 ]

    expected='{
  "name": "test",
  "value": 123
}'

    [ "$(cat "$CONFIG_FILE")" = "$expected" ]
}

@test "Save-Config: rejects empty configuration" {
    run Save-Config ""

    [ "$status" -eq 1 ]
    [ "$output" = "Error" ]

    [ ! -f "$CONFIG_FILE" ]
}

@test "Save-Config: rejects invalid JSON" {
    run Save-Config '{ invalid json'

    [ "$status" -eq 1 ]
    [ "$output" = "Error" ]

    [ ! -f "$CONFIG_FILE" ]
}

@test "Save-Config: rejects whitespace-only configuration" {
    run Save-Config "   "

    [ "$status" -eq 1 ]
    [ "$output" = "Error" ]

    [ ! -f "$CONFIG_FILE" ]
}

@test "Save-Config: accepts valid JSON object" {
    run Save-Config '{"test":true}'

    [ "$status" -eq 0 ]
    [ "$output" = "success save" ]

    run jq -e '.test == true' "$CONFIG_FILE"

    [ "$status" -eq 0 ]
}

@test "Save-Config: accepts valid JSON array" {
    run Save-Config '["one","two"]'

    [ "$status" -eq 0 ]
    [ "$output" = "success save" ]

    run jq -e 'length == 2' "$CONFIG_FILE"

    [ "$status" -eq 0 ]
}

@test "Save-Config: accepts JSON containing special characters" {
    config='{
        "name": "Backup éèà",
        "path": "/tmp/my folder/test",
        "value": "quotes: \"hello\""
    }'

    run Save-Config "$config"

    [ "$status" -eq 0 ]

    run jq -e \
        '.name == "Backup éèà"
         and .path == "/tmp/my folder/test"
         and .value == "quotes: \"hello\""' \
        "$CONFIG_FILE"

    [ "$status" -eq 0 ]
}

@test "Save-Config: creates missing config directory" {
    rm -rf "$CONFIG_DIR"

    run Save-Config '{"test":true}'

    [ "$status" -eq 0 ]
    [ -d "$CONFIG_DIR" ]
    [ -f "$CONFIG_FILE" ]
}

@test "Save-Config: overwrites existing configuration" {
    printf '%s\n' '{"old":true}' > "$CONFIG_FILE"

    run Save-Config '{"new":true}'

    [ "$status" -eq 0 ]

    run jq -e '.new == true and .old == null' "$CONFIG_FILE"

    [ "$status" -eq 0 ]
}

@test "Save-Config: writes valid JSON to disk" {
    run Save-Config '{
        "backupDrive": {
            "uuid": "abc"
        },
        "sources": [
            "/one",
            "/two"
        ]
    }'

    [ "$status" -eq 0 ]

    run jq empty "$CONFIG_FILE"

    [ "$status" -eq 0 ]
}


# ============================================================
# Show-Config
# ============================================================

@test "Show-Config: fails when Get-Config fails" {
    Get-Config() {
        return 1
    }

    run Show-Config

    [ "$status" -eq 1 ]
    [ "$output" = "failed" ]
}

@test "Show-Config: displays no backup drive when UUID is missing" {
    Get-Config() {
        cat <<'EOF'
{
    "backupDrive": {
        "uuid": "",
        "name": "",
        "size": ""
    },
    "backupFolder": "Backup",
    "sources": [],
    "language": "en"
}
EOF
    }

    clear() {
        :
    }

    run Show-Config

    [ "$status" -eq 0 ]

    [[ "$output" == *"current config"* ]]
    [[ "$output" == *"Backup Drive :"* ]]
    [[ "$output" == *"No Backup Drive"* ]]
    [[ "$output" == *"Folder : Backup"* ]]
    [[ "$output" == *"Sources :"* ]]
    [[ "$output" == *"No Sources"* ]]
    [[ "$output" == *"Language : en"* ]]
}

@test "Show-Config: displays backup drive information" {
    Get-Config() {
        cat <<'EOF'
{
    "backupDrive": {
        "uuid": "ABCD-1234",
        "name": "My Backup Drive",
        "size": "1TB"
    },
    "backupFolder": "Backup",
    "sources": [],
    "language": "en"
}
EOF
    }

    clear() {
        :
    }

    run Show-Config

    [ "$status" -eq 0 ]

    [[ "$output" == *"Letter : ABCD-1234"* ]]
    [[ "$output" == *"Name : My Backup Drive"* ]]
    [[ "$output" == *"Size : 1TB"* ]]
}

@test "Show-Config: displays configured backup folder" {
    Get-Config() {
        printf '%s\n' '{
            "backupDrive": {
                "uuid": "1234",
                "name": "Drive",
                "size": "1TB"
            },
            "backupFolder": "MyBackup",
            "sources": [],
            "language": "en"
        }'
    }

    clear() {
        :
    }

    run Show-Config

    [ "$status" -eq 0 ]
    [[ "$output" == *"Folder : MyBackup"* ]]
}

@test "Show-Config: displays no sources when source list is empty" {
    Get-Config() {
        printf '%s\n' '{
            "backupDrive": {
                "uuid": "1234",
                "name": "Drive",
                "size": "1TB"
            },
            "backupFolder": "Backup",
            "sources": [],
            "language": "en"
        }'
    }

    clear() {
        :
    }

    run Show-Config

    [ "$status" -eq 0 ]
    [[ "$output" == *"Sources :"* ]]
    [[ "$output" == *"No Sources"* ]]
}

@test "Show-Config: displays all configured sources" {
    Get-Config() {
        printf '%s\n' '{
            "backupDrive": {
                "uuid": "1234",
                "name": "Drive",
                "size": "1TB"
            },
            "backupFolder": "Backup",
            "sources": [
                "/source/one",
                "/source/two",
                "/source/three"
            ],
            "language": "fr"
        }'
    }

    clear() {
        :
    }

    run Show-Config

    [ "$status" -eq 0 ]

    [[ "$output" == *"   /source/one"* ]]
    [[ "$output" == *"   /source/two"* ]]
    [[ "$output" == *"   /source/three"* ]]
}

@test "Show-Config: preserves source order" {
    Get-Config() {
        printf '%s\n' '{
            "backupDrive": {
                "uuid": "1234",
                "name": "Drive",
                "size": "1TB"
            },
            "backupFolder": "Backup",
            "sources": [
                "alpha",
                "beta",
                "gamma"
            ],
            "language": "en"
        }'
    }

    clear() {
        :
    }

    run Show-Config

    [ "$status" -eq 0 ]

    alpha_pos=$(grep -nF "   alpha" <<< "$output" | cut -d: -f1)
    beta_pos=$(grep -nF "   beta" <<< "$output" | cut -d: -f1)
    gamma_pos=$(grep -nF "   gamma" <<< "$output" | cut -d: -f1)

    [ "$alpha_pos" -lt "$beta_pos" ]
    [ "$beta_pos" -lt "$gamma_pos" ]
}

@test "Show-Config: displays configured language" {
    Get-Config() {
        printf '%s\n' '{
            "backupDrive": {
                "uuid": "1234",
                "name": "Drive",
                "size": "1TB"
            },
            "backupFolder": "Backup",
            "sources": [],
            "language": "fr"
        }'
    }

    clear() {
        :
    }

    run Show-Config

    [ "$status" -eq 0 ]
    [[ "$output" == *"Language : fr"* ]]
}


# ============================================================
# Integration
# ============================================================

@test "Get-Config and Save-Config work together" {
    config='{
        "backupDrive": {
            "uuid": "1234",
            "name": "Drive",
            "size": "2TB"
        },
        "backupFolder": "MyBackup",
        "sources": [
            "/source/one",
            "/source/two"
        ],
        "language": "fr"
    }'

    run Save-Config "$config"

    [ "$status" -eq 0 ]

    run Get-Config

    [ "$status" -eq 0 ]

    run jq -S '.' <<< "$output"
    [ "$status" -eq 0 ]

    expected="$(jq -S '.' <<< "$config")"

    [ "$output" = "$expected" ]
}

@test "Get-Config: creates config directory when missing" {
    rm -rf "$CONFIG_DIR"

    run Get-Config

    [ "$status" -eq 0 ]
    [ -d "$CONFIG_DIR" ]
    [ -f "$CONFIG_FILE" ]
}

@test "Save-Config followed by Get-Config returns equivalent JSON" {
    config='{
        "foo": "bar",
        "number": 42,
        "enabled": true,
        "items": ["one", "two"]
    }'

    Save-Config "$config"

    run Get-Config

    [ "$status" -eq 0 ]

    run jq -e --argjson expected "$config" '. == $expected' <<< "$output"

    [ "$status" -eq 0 ]
}