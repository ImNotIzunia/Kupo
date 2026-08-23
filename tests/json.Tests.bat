#!/usr/bin/env bats

setup() {
    CONFIG_FILE="$BATS_TEST_DIRNAME/../config/config.tests.json"
}

####################################################
# Configuration file
####################################################

@test "Configuration file: exists" {
    [ -f "$CONFIG_FILE" ]
}

@test "Configuration file: contains valid JSON" {
    run jq empty "$CONFIG_FILE"

    [ "$status" -eq 0 ]
}

@test "Configuration file: contains a valid JSON object" {
    run jq -e 'type == "object"' "$CONFIG_FILE"

    [ "$status" -eq 0 ]
}

####################################################
# Configuration structure
####################################################

@test "Configuration file: contains backupDrive" {
    run jq -e '.backupDrive' "$CONFIG_FILE"

    [ "$status" -eq 0 ]
}

@test "Configuration file: contains backupDrive.uuid" {
    run jq -e '.backupDrive | has("uuid")' "$CONFIG_FILE"

    [ "$status" -eq 0 ]
}

@test "Configuration file: contains backupDrive.name" {
    run jq -e '.backupDrive | has("name")' "$CONFIG_FILE"

    [ "$status" -eq 0 ]
}

@test "Configuration file: contains backupDrive.size" {
    run jq -e '.backupDrive | has("size")' "$CONFIG_FILE"

    [ "$status" -eq 0 ]
}

@test "Configuration file: contains backupFolder" {
    run jq -e 'has("backupFolder")' "$CONFIG_FILE"

    [ "$status" -eq 0 ]
}

@test "Configuration file: contains sources" {
    run jq -e 'has("sources")' "$CONFIG_FILE"

    [ "$status" -eq 0 ]
}

@test "Configuration file: contains language" {
    run jq -e 'has("language")' "$CONFIG_FILE"

    [ "$status" -eq 0 ]
}

####################################################
# Default values
####################################################

@test "Configuration file: backupDrive.uuid is empty by default" {
    run jq -r '.backupDrive.uuid' "$CONFIG_FILE"

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "Configuration file: backupDrive.name is empty by default" {
    run jq -r '.backupDrive.name' "$CONFIG_FILE"

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "Configuration file: backupDrive.size is empty by default" {
    run jq -r '.backupDrive.size' "$CONFIG_FILE"

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "Configuration file: backupFolder defaults to Backup" {
    run jq -r '.backupFolder' "$CONFIG_FILE"

    [ "$status" -eq 0 ]
    [ "$output" = "Backup" ]
}

@test "Configuration file: sources is an empty array by default" {
    run jq -e '.sources | type == "array" and length == 0' "$CONFIG_FILE"

    [ "$status" -eq 0 ]
}

@test "Configuration file: language defaults to en" {
    run jq -r '.language' "$CONFIG_FILE"

    [ "$status" -eq 0 ]
    [ "$output" = "en" ]
}

