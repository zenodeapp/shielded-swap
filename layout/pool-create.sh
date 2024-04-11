#!/bin/bash

# Source shared functions
source helpers/shared.sh

# Source input functions
source helpers/input.sh

# Header
header_block "OSMOSIS POOL CREATION"
gum log --level warn --structured "IMPORTANT: make sure to fund the pool with sufficient tokens, else the swaps will cost more than you receive causing shielded actions to fail."
CONFIRM_CREATE=$(gum confirm "Do you want to continue?" && echo "true" || echo "false")

if [ "$CONFIRM_CREATE" = "true" ]; then
  RATIO=$(repeat_input_ratio "What's the uosmo:$NAM_DENOM ratio? (default: 5:1)")
  UOSMO_DEPOSIT=$(repeat_input_number "Enter the amount of uosmo you'll deposit ('1000000' equals 1 OSMO) [default: 100000000]")
  NAM_DEPOSIT=$(repeat_input_number "Enter the amount of $NAM_DENOM you'll deposit [default: 20]")

  # Set defaults
  if [ -z "$RATIO" ]; then
    RATIO="5:1"
  fi

  if [ -z "$UOSMO_DEPOSIT" ]; then
    UOSMO_DEPOSIT=100000000
  fi

  if [ -z "$NAM_DEPOSIT" ]; then
    NAM_DEPOSIT=20
  fi

  # Extract numbers from ratio
  IFS=':' read -r WEIGHT1 WEIGHT2 <<< "$RATIO"

  # Generate the pool.json file
  gum spin --title "Generating pool.json file..." -- sleep 1
  if create_osmosis_pool_json "uosmo" "$NAM_IBC" "$WEIGHT1" "$WEIGHT2" "$UOSMO_DEPOSIT" "$NAM_DEPOSIT"; then
    echo_success 'pool.json generated!'

    # Create pool
    gum spin --show-output --title "Creating osmosis pool transaction..." -- sleep 1
    if create_osmosis_pool ".tmp/pool.json"; then
      echo_success 'Osmosis pool created!'
    else
      echo_fail "Failed to create osmosis pool!"
    fi
  else
    echo_fail "Failed to generate pool.json!"
  fi

  # Menu
  CHOICE_SEE_POOLS="1. Point to a pool you own"
  CHOICE_BACK="Back"

  MENU_CHOICE=$(gum choose  --header "What would you like to do?" "$CHOICE_SEE_POOLS" "$CHOICE_BACK")

  if [ "$MENU_CHOICE" = "$CHOICE_SEE_POOLS" ]; then
    bash layout/pool-own.sh
  else
    bash layout/pool.sh
  fi
else
  bash layout/pool.sh
fi