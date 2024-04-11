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
    # This means a field is empty, so give an error.
    gum log --structured --level error "Not all required keys are configured, make sure to do this using 4. Configuration!"
    NAM_RPC_VALUE=$(jq -r '.namRpc' "$CONFIG_FILE")
    # Common mistake is to not set the rpc to the correct value, so give a warning if it's on the default!
    if [ "$NAM_RPC_VALUE" = "http://127.0.0.1:26657" ]; then
      gum log --structured --level warn "Namada RPC is set to the default: http://127.0.0.1:26657, if this is correct ignore this warning."
    fi
    echo ""
  fi
}