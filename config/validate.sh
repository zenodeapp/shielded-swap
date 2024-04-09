#!/bin/bash

# From https://github.com/zenodeapp/namada-proposals/blob/main/dependencies/process_config.sh.
# Adapted to the current repo.

KEYS_FILE="config/_keys.txt"
CONFIG_FILE="config/config.json"

# Check if the keys file exists
if [ ! -f "$KEYS_FILE" ]; then
  gum log --structured --level error "Configuration file $KEYS_FILE not found."
  exit 1
fi

# Check if the configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
  gum log --structured --level error "Configuration file $CONFIG_FILE not found."
  exit 1
fi

# Check if the JSON is valid
if ! jq empty "$CONFIG_FILE" > /dev/null 2>&1; then
  gum log --structured --level error "Invalid JSON in $CONFIG_FILE."
  exit 1
fi

# Read all keys from the _keys.txt file and store it in a variable for the final check
keys=''

while IFS= read -r line; do
    keys+="has(\"$line\") and "
done < "$KEYS_FILE"

# Remove trailing ' and '
keys=${keys%and }

# Check if the required keys are present in the json
if ! jq -e ". | $keys" "$CONFIG_FILE" > /dev/null 2>&1; then
  gum log --structured --level error "Missing required key(s) in $CONFIG_FILE."
  exit 1
fi