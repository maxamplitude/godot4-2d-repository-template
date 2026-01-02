#!/bin/sh

# Run the tests
export GODOT_BIN=$(which godot)

$(dirname $0)/../addons/gdUnit4/runtest.sh -a res://src/tests

# echo "Copying log..."
# # Run the copy log command
# godot --headless --path . --quiet -s res://addons/gdUnit4/bin/GdUnitCopyLog.gd > /dev/null
