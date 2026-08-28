#!/usr/bin/env bats

setup() {
    TEST_DIR="$(mktemp -d)"
    CONFIG_FILE="$TEST_DIR/config.saved.json"

    TEST_CONFIG='{
        "sources": []
    }'

    source "$BATS_TEST_DIRNAME/../functions/sources.sh"

    # Mock de Get-Config
    Get-Config() {
        printf '%s\n' "$TEST_CONFIG"
    }

    # Mock de Save-Config
    Save-Config() {
        printf '%s\n' "$1" > "$CONFIG_FILE"
    }

    # Mock de Get-String
    Get-String() {
        case "$1" in
            source.nosources)
                printf '%s' "   No Sources"
                ;;
            source.configerror)
                printf '%s' "failed"
                ;;
            source.addinvalid)
                printf '%s' "failed"
                ;;
            source.addnotexist)
                printf '%s' "not found"
                ;;
            source.addduplicate)
                printf '%s' "already exists"
                ;;
            source.addsuccess)
                printf '%s' "success"
                ;;
            source.failedsave)
                printf '%s' "failed to save"
                ;;
            source.deletenosources)
                printf '%s' "No sources"
                ;;
            source.deletechoice)
                printf '%s' "Choose source"
                ;;
            source.deleteinvalid)
                printf '%s' "invalid"
                ;;
            source.deletesuccess)
                printf '%s' "success"
                ;;
        esac
    }

    # Mock de Write-Log
    Write-Log() {
        :
    }
}

teardown() {
    rm -rf "$TEST_DIR"
}

# ============================================================
# Helpers
# ============================================================

assert_saved_sources_count() {
    local expected="$1"

    run jq '.sources | length' "$CONFIG_FILE"

    [ "$status" -eq 0 ]
    [ "$output" = "$expected" ]
}

assert_saved_source() {
    local index="$1"
    local expected="$2"

    run jq -r ".sources[$index]" "$CONFIG_FILE"

    [ "$status" -eq 0 ]
    [ "$output" = "$expected" ]
}


# ============================================================
# Get-Source
# ============================================================

@test "Get-Source: displays 'No Sources' when empty" {
    run Get-Source

    [ "$status" -eq 0 ]
    [ "$output" = "   No Sources" ]
}

@test "Get-Source: lists all configured sources" {
    TEST_CONFIG='{
        "sources": [
            "/tmp/source1",
            "/tmp/source2",
            "/tmp/source3"
        ]
    }'

    run Get-Source

    [ "$status" -eq 0 ]

    expected=$'1. /tmp/source1\n2. /tmp/source2\n3. /tmp/source3'

    [ "$output" = "$expected" ]
}

@test "Get-Source: preserves source order" {
    TEST_CONFIG='{
        "sources": [
            "/first",
            "/second",
            "/third"
        ]
    }'

    run Get-Source

    [ "$status" -eq 0 ]

    expected=$'1. /first\n2. /second\n3. /third'

    [ "$output" = "$expected" ]
}

@test "Get-Source: reports Get-Config failure" {
    Get-Config() {
        return 1
    }

    run Get-Source

    [ "$status" -eq 1 ]
    [ "$output" = "failed" ]
}


# ============================================================
# Add-Source
# ============================================================

@test "Add-Source: adds a valid directory" {
    mkdir "$TEST_DIR/source"

    printf '%s\n' "$TEST_DIR/source" > "$TEST_DIR/input"

    run Add-Source < "$TEST_DIR/input"

    [ "$status" -eq 0 ]
    [ "$output" = "success" ]

    assert_saved_sources_count 1
    assert_saved_source 0 "$TEST_DIR/source"
}

@test "Add-Source: adds multiple different directories" {
    mkdir "$TEST_DIR/source1"
    mkdir "$TEST_DIR/source2"

    TEST_CONFIG='{
        "sources": [
            "'"$TEST_DIR"'/source1"
        ]
    }'

    printf '%s\n' "$TEST_DIR/source2" > "$TEST_DIR/input"

    run Add-Source < "$TEST_DIR/input"

    [ "$status" -eq 0 ]
    [ "$output" = "success" ]

    assert_saved_sources_count 2
    assert_saved_source 0 "$TEST_DIR/source1"
    assert_saved_source 1 "$TEST_DIR/source2"
}

@test "Add-Source: resolves directory to absolute path" {
    mkdir "$TEST_DIR/source"

    (
        cd "$TEST_DIR" || exit 1
        printf '%s\n' './source' > "$TEST_DIR/input"

        run Add-Source < "$TEST_DIR/input"

        [ "$status" -eq 0 ]
        [ "$output" = "success" ]
    )

    assert_saved_sources_count 1
    assert_saved_source 0 "$TEST_DIR/source"
}

@test "Add-Source: resolves directory to physical path" {
    mkdir "$TEST_DIR/source"
    mkdir "$TEST_DIR/other"

    ln -s "$TEST_DIR/source" "$TEST_DIR/link"

    printf '%s\n' "$TEST_DIR/link" > "$TEST_DIR/input"

    run Add-Source < "$TEST_DIR/input"

    [ "$status" -eq 0 ]
    [ "$output" = "success" ]

    assert_saved_sources_count 1
    assert_saved_source 0 "$TEST_DIR/source"
}

@test "Add-Source: rejects empty input" {
    printf '\n' > "$TEST_DIR/input"

    run Add-Source < "$TEST_DIR/input"

    [ "$status" -eq 1 ]
    [ "$output" = "failed" ]
}

@test "Add-Source: rejects whitespace-only input" {
    printf '    \n' > "$TEST_DIR/input"

    run Add-Source < "$TEST_DIR/input"

    [ "$status" -eq 1 ]
    [ "$output" = "failed" ]
}

@test "Add-Source: rejects EOF without input" {
    run Add-Source < /dev/null

    [ "$status" -eq 1 ]
    [ "$output" = "failed" ]
}

@test "Add-Source: rejects missing directory" {
    printf '%s\n' "$TEST_DIR/does-not-exist" > "$TEST_DIR/input"

    run Add-Source < "$TEST_DIR/input"

    [ "$status" -eq 1 ]
    [ "$output" = "not found" ]
}

@test "Add-Source: rejects duplicate directory" {
    mkdir "$TEST_DIR/source"

    TEST_CONFIG=$(
        jq \
            --arg path "$TEST_DIR/source" \
            '.sources = [$path]' <<< "$TEST_CONFIG"
    )

    printf '%s\n' "$TEST_DIR/source" > "$TEST_DIR/input"

    run Add-Source < "$TEST_DIR/input"

    [ "$status" -eq 1 ]
    [ "$output" = "already exists" ]
}

@test "Add-Source: rejects duplicate directory through symlink" {
    mkdir "$TEST_DIR/source"
    ln -s "$TEST_DIR/source" "$TEST_DIR/link"

    TEST_CONFIG=$(
        jq \
            --arg path "$TEST_DIR/source" \
            '.sources = [$path]' <<< "$TEST_CONFIG"
    )

    printf '%s\n' "$TEST_DIR/link" > "$TEST_DIR/input"

    run Add-Source < "$TEST_DIR/input"

    [ "$status" -eq 1 ]
    [ "$output" = "already exists" ]
}

@test "Add-Source: reports Get-Config failure" {
    Get-Config() {
        return 1
    }

    mkdir "$TEST_DIR/source"
    printf '%s\n' "$TEST_DIR/source" > "$TEST_DIR/input"

    run Add-Source < "$TEST_DIR/input"

    [ "$status" -eq 1 ]
    [ "$output" = "failed" ]
}

@test "Add-Source: reports Save-Config failure" {
    Save-Config() {
        return 1
    }

    mkdir "$TEST_DIR/source"
    printf '%s\n' "$TEST_DIR/source" > "$TEST_DIR/input"

    run Add-Source < "$TEST_DIR/input"

    [ "$status" -eq 1 ]
    [ "$output" = "failed to save" ]
}

@test "Add-Source: does not save when directory is invalid" {
    printf '%s\n' "$TEST_DIR/missing" > "$TEST_DIR/input"

    run Add-Source < "$TEST_DIR/input"

    [ "$status" -eq 1 ]
    [ "$output" = "not found" ]

    [ ! -f "$CONFIG_FILE" ]
}


# ============================================================
# Delete-Source
# ============================================================

@test "Delete-Source: fails when there are no sources" {
    run Delete-Source

    [ "$status" -eq 1 ]
    [ "$output" = "No sources" ]
}

@test "Delete-Source: removes first source" {
    TEST_CONFIG='{
        "sources": [
            "/tmp/source1",
            "/tmp/source2",
            "/tmp/source3"
        ]
    }'

    printf '1\n' > "$TEST_DIR/input"

    run Delete-Source < "$TEST_DIR/input"

    [ "$status" -eq 0 ]
    [ "$output" = $'1. /tmp/source1\n2. /tmp/source2\n3. /tmp/source3\n\nsuccess' ]

    assert_saved_sources_count 2
    assert_saved_source 0 "/tmp/source2"
    assert_saved_source 1 "/tmp/source3"
}

@test "Delete-Source: removes middle source" {
    TEST_CONFIG='{
        "sources": [
            "/tmp/source1",
            "/tmp/source2",
            "/tmp/source3"
        ]
    }'

    printf '2\n' > "$TEST_DIR/input"

    run Delete-Source < "$TEST_DIR/input"

    [ "$status" -eq 0 ]
    [ "$output" = $'1. /tmp/source1\n2. /tmp/source2\n3. /tmp/source3\n\nsuccess' ]

    assert_saved_sources_count 2
    assert_saved_source 0 "/tmp/source1"
    assert_saved_source 1 "/tmp/source3"
}

@test "Delete-Source: removes last source" {
    TEST_CONFIG='{
        "sources": [
            "/tmp/source1",
            "/tmp/source2",
            "/tmp/source3"
        ]
    }'

    printf '3\n' > "$TEST_DIR/input"

    run Delete-Source < "$TEST_DIR/input"

    [ "$status" -eq 0 ]
    [ "$output" = $'1. /tmp/source1\n2. /tmp/source2\n3. /tmp/source3\n\nsuccess' ]

    assert_saved_sources_count 2
    assert_saved_source 0 "/tmp/source1"
    assert_saved_source 1 "/tmp/source2"
}

@test "Delete-Source: rejects index below minimum" {
    TEST_CONFIG='{
        "sources": [
            "/tmp/source1"
        ]
    }'

    printf '0\n' > "$TEST_DIR/input"

    run Delete-Source < "$TEST_DIR/input"

    [ "$status" -eq 1 ]
    [ "$output" = $'1. /tmp/source1\n\ninvalid' ]
}

@test "Delete-Source: rejects index above maximum" {
    TEST_CONFIG='{
        "sources": [
            "/tmp/source1"
        ]
    }'

    printf '2\n' > "$TEST_DIR/input"

    run Delete-Source < "$TEST_DIR/input"

    [ "$status" -eq 1 ]
    [ "$output" = $'1. /tmp/source1\n\ninvalid' ]
}

@test "Delete-Source: rejects negative index" {
    TEST_CONFIG='{
        "sources": [
            "/tmp/source1"
        ]
    }'

    printf '%s\n' '-1' > "$TEST_DIR/input"

    run Delete-Source < "$TEST_DIR/input"

    [ "$status" -eq 1 ]
    [ "$output" = $'1. /tmp/source1\n\ninvalid' ]
}

@test "Delete-Source: rejects non numeric index" {
    TEST_CONFIG='{
        "sources": [
            "/tmp/source1"
        ]
    }'

    printf 'abc\n' > "$TEST_DIR/input"

    run Delete-Source < "$TEST_DIR/input"

    [ "$status" -eq 1 ]
    [ "$output" = $'1. /tmp/source1\n\ninvalid' ]
}

@test "Delete-Source: rejects decimal index" {
    TEST_CONFIG='{
        "sources": [
            "/tmp/source1"
        ]
    }'

    printf '1.5\n' > "$TEST_DIR/input"

    run Delete-Source < "$TEST_DIR/input"

    [ "$status" -eq 1 ]
    [ "$output" = $'1. /tmp/source1\n\ninvalid' ]
}

@test "Delete-Source: rejects empty input" {
    TEST_CONFIG='{
        "sources": [
            "/tmp/source1"
        ]
    }'

    printf '\n' > "$TEST_DIR/input"

    run Delete-Source < "$TEST_DIR/input"

    [ "$status" -eq 1 ]
    [ "$output" = $'1. /tmp/source1\n\ninvalid' ]
}

@test "Delete-Source: rejects EOF without input" {
    TEST_CONFIG='{
        "sources": [
            "/tmp/source1"
        ]
    }'

    run Delete-Source < /dev/null

    [ "$status" -eq 1 ]
    [ "$output" = $'1. /tmp/source1\n\ninvalid' ]
}

@test "Delete-Source: reports Get-Config failure" {
    Get-Config() {
        return 1
    }

    run Delete-Source

    [ "$status" -eq 1 ]
    [ "$output" = "failed" ]
}

@test "Delete-Source: reports Save-Config failure" {
    TEST_CONFIG='{
        "sources": [
            "/tmp/source1"
        ]
    }'

    Save-Config() {
        return 1
    }

    printf '1\n' > "$TEST_DIR/input"

    run Delete-Source < "$TEST_DIR/input"

    [ "$status" -eq 1 ]
    [ "$output" = $'1. /tmp/source1\n\nfailed to save' ]
}


# ============================================================
# Integration-style behavior
# ============================================================

@test "Add-Source then Delete-Source updates configuration correctly" {
    mkdir "$TEST_DIR/source1"
    mkdir "$TEST_DIR/source2"

    # Add source 1
    printf '%s\n' "$TEST_DIR/source1" > "$TEST_DIR/input"

    run Add-Source < "$TEST_DIR/input"

    [ "$status" -eq 0 ]
    [ "$output" = "success" ]

    # Simule la persistance réelle pour le prochain Get-Config
    TEST_CONFIG="$(cat "$CONFIG_FILE")"

    # Add source 2
    printf '%s\n' "$TEST_DIR/source2" > "$TEST_DIR/input"

    run Add-Source < "$TEST_DIR/input"

    [ "$status" -eq 0 ]
    [ "$output" = "success" ]

    TEST_CONFIG="$(cat "$CONFIG_FILE")"

    assert_saved_sources_count 2

    # Delete source 1
    printf '1\n' > "$TEST_DIR/input"

    run Delete-Source < "$TEST_DIR/input"

    [ "$status" -eq 0 ]

    TEST_CONFIG="$(cat "$CONFIG_FILE")"

    assert_saved_sources_count 1
    assert_saved_source 0 "$TEST_DIR/source2"
}


# ============================================================
# JSON integrity
# ============================================================

@test "Add-Source: saves valid JSON" {
    mkdir "$TEST_DIR/source"

    printf '%s\n' "$TEST_DIR/source" > "$TEST_DIR/input"

    run Add-Source < "$TEST_DIR/input"

    [ "$status" -eq 0 ]

    run jq empty "$CONFIG_FILE"

    [ "$status" -eq 0 ]
}

@test "Delete-Source: saves valid JSON" {
    TEST_CONFIG='{
        "sources": [
            "/tmp/source1",
            "/tmp/source2"
        ]
    }'

    printf '1\n' > "$TEST_DIR/input"

    run Delete-Source < "$TEST_DIR/input"

    [ "$status" -eq 0 ]

    run jq empty "$CONFIG_FILE"

    [ "$status" -eq 0 ]
}

