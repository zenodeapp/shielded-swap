#!/bin/bash

# From https://github.com/zenodeapp/namada-proposals/blob/main/dependencies/process_config.sh, adapted to the current repo.

CONFIG_FILE="config/config.json"

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

# Check if required keys are present
if ! jq -e '. |
    has("nam") and
    has("namIbc") and
    has("namChannel") and
    has("namRpc") and
    has("osmoChannel") and
    has("osmoPoolId") and
    has("addresses") and
    has("shieldedBroken") and
    has("osmoRpc") and
    (.addresses |
    has("namTransparent") and
    has("namShielded") and
    has("namViewingKey") and
    has("osmoAddress"))' "$CONFIG_FILE" > /dev/null 2>&1
then
    gum log --structured --level error "Missing required key(s) in $CONFIG_FILE."
    exit 1
fi

# Parse config.json
export NAM=$(jq -r '.nam' $CONFIG_FILE)
export NAM_IBC=$(jq -r '.namIbc' $CONFIG_FILE)
export NAM_CHANNEL=$(jq -r '.namChannel' $CONFIG_FILE)
export NAM_RPC=$(jq -r '.namRpc' $CONFIG_FILE)
export OSMO_CHANNEL=$(jq -r '.osmoChannel' $CONFIG_FILE)
export OSMO_POOL_ID=$(jq -r '.osmoPoolId' $CONFIG_FILE)
export OSMO_RPC=$(jq -r '.osmoRpc' $CONFIG_FILE)
export NAM_TRANSPARENT=$(jq -r '.addresses.namTransparent' $CONFIG_FILE)
export NAM_SHIELDED=$(jq -r '.addresses.namShielded' $CONFIG_FILE)
export NAM_VIEWING_KEY=$(jq -r '.addresses.namViewingKey' $CONFIG_FILE)
export OSMO_ADDRESS=$(jq -r '.addresses.osmoAddress' $CONFIG_FILE)
export SHIELDED_BROKEN=$(jq -r '.shieldedBroken' $CONFIG_FILE)

# Useful
export NAM_UOSMO_DENOM="transfer/$NAM_CHANNEL/uosmo"