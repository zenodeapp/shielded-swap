#!/bin/bash

# Source helper functions
source helpers/shared.sh

# Source config setter
source config/set.sh

# Check pools you own
CHOICES=$(get_gamm_pool_denoms)

if [ -z "$CHOICES" ]; then
  gum log --structured --level warn "$OSMO_ADDRESS does not own any pools!"
  bash layout/pool.sh
else
  SELECTED=$(gum choose --header "Pools $OSMO_ADDRESS owns:" $CHOICES)

  # Extract pool ID from denom
  IFS='/' read -ra PARTS <<< "$SELECTED"
  POOL_ID="${PARTS[2]}"

  # Change this value in the json file
  modify_config_key "osmoPoolId" "$POOL_ID"
  echo "Set osmoPoolId to: $POOL_ID!"
fi

# Menu
CHOICE_BACK="Back to pools"

MENU_CHOICE=$(gum choose  --header "What would you like to do?" "$CHOICE_BACK")

if [ "$MENU_CHOICE" = "$CHOICE_BACK" ]; then
  bash layout/pool.sh
fi