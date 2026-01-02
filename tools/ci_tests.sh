#!/bin/sh

# CI Test Script
# Bypasses wrappers to ensure Godot 4 engine flags are in the correct order.

GODOT_BIN=$(which godot)
export GODOT_BIN

BUILD_DIR="$(pwd)/builds"
LOG_FILE="$BUILD_DIR/godot_log/godot-tests.log"
USER_DATA_DIR="$BUILD_DIR/user_data"

mkdir -p "$(dirname "$LOG_FILE")" "$USER_DATA_DIR"

echo "Starting Godot Headless Tests..."
"$(dirname "$0")/../addons/gdUnit4/runtest.sh" --headless -a res://src/tests


EXIT_CODE=$?
echo "Godot process finished with exit code: $EXIT_CODE"
exit $EXIT_CODE
