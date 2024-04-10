#!/bin/bash

# Source shared functions
source helpers/shared.sh

# Source input functions
source helpers/input.sh

echo "OSMOSIS POOL CREATION"
RATIO=$(repeat_input_ratio "What's the uosmo:$NAM_DENOM ratio? (default: 5:1)")
UOSMO_DEPOSIT=$(repeat_input_number "Enter the amount of uosmo you'll deposit ('1000000' equals 1 OSMO) [default: 1000]")
NAM_DEPOSIT=$(repeat_input_number "Enter the amount of $NAM_DENOM you'll deposit [default: 200]")

# Set defaults
if [ -z "$RATIO" ]; then
  RATIO="5:1"
fi

if [ -z "$UOSMO_DEPOSIT" ]; then
  UOSMO_DEPOSIT=1000
fi

if [ -z "$NAM_DEPOSIT" ]; then
  NAM_DEPOSIT=200
fi

# Extract numbers from ratio
IFS=':' read -r WEIGHT1 WEIGHT2 <<< "$RATIO"

# Generate the pool.json file
gum spin --spinner dot --title "Generating pool.json file..." -- sleep 1
if create_osmosis_pool_json "uosmo" "$NAM_IBC" "$WEIGHT1" "$WEIGHT2" "$UOSMO_DEPOSIT" "$NAM_DEPOSIT"; then
  echo "pool.json generated!"

  # Create pool
  echo ""
  if create_osmosis_pool ".tmp/pool.json"; then
    echo "Osmosis pool created!"
  else
    echo "Failed to create osmosis pool!"
  fi
else
  echo "Failed to generate pool.json!"
fi

# Menu
CHOICE_SEE_POOLS="1. Point to a pool you own"
CHOICE_BACK="Back"

MENU_CHOICE=$(gum choose  --header "What would you like to do?" "$CHOICE_SEE_POOLS" "$CHOICE_BACK")

if [ "$MENU_CHOICE" = "$CHOICE_SEE_POOLS" ]; then
  bash layout/pool-own.sh
elif [ "$MENU_CHOICE" = "$CHOICE_BACK" ]; then
  bash layout/pool.sh
fi