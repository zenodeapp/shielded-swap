#!/bin/bash

# Always validate before using configurations
source config/validate.sh

# Parse config.json
export SHIELDED_BROKEN=$(jq -r '.shieldedBroken' $CONFIG_FILE)
export NAM_CHAIN_ID=$(jq -r '.namChainId' $CONFIG_FILE)
export OSMO_CHAIN_ID=$(jq -r '.osmoChainId' $CONFIG_FILE)
export NAM_RPC=$(jq -r '.namRpc' $CONFIG_FILE)
export OSMO_RPC=$(jq -r '.osmoRpc' $CONFIG_FILE)

export OSMO_POOL_ID=$(jq -r '.osmoPoolId' $CONFIG_FILE)
export NAM_DENOM=$(jq -r '.namDenom' $CONFIG_FILE)
export NAM_IBC=$(jq -r '.namIbc' $CONFIG_FILE)
export NAM_CHANNEL=$(jq -r '.namChannel' $CONFIG_FILE)
export OSMO_CHANNEL=$(jq -r '.osmoChannel' $CONFIG_FILE)

export NAM_TRANSPARENT=$(jq -r '.namTransparent' $CONFIG_FILE)
export NAM_VIEWING_KEY=$(jq -r '.namViewingKey' $CONFIG_FILE)
export NAM_SHIELDED=$(jq -r '.namShielded' $CONFIG_FILE)

export OSMO_KEY=$(jq -r '.osmoKey' $CONFIG_FILE)
export OSMO_ADDRESS=$(jq -r '.osmoAddress' $CONFIG_FILE)

# Useful derivatives
if [ -z "$NAM_CHANNEL" ]; then
    export NAM_UOSMO_DENOM=""
else
    export NAM_UOSMO_DENOM="transfer/$NAM_CHANNEL/uosmo"
fi