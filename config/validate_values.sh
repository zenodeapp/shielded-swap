#!/bin/bash

# Could have more advanced validation checks here

KEYS_FILE="config/_keys.txt"
CONFIG_FILE="config.json"

check_config_values() {
  ERR_TRIGGERED=false

  while IFS= read -r key; do
    VALUE=$(jq -r --arg key "$key" '.[$key]' "$CONFIG_FILE")

    if [ -z "$VALUE" ]; then
      # gum log --structured --level error "$key in the config.json file is empty!"
      ERR_TRIGGERED=true
    fi
  done < "$KEYS_FILE"

  if $ERR_TRIGGERED; then
    gum log --structured --level warn "Not all required keys are configured, make sure to do this using 4. Configuration!"
    echo ""
  fi
}