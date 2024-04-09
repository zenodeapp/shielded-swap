#!/bin/bash

# Menu
CHOICE_CONFIG="1. Configurations"
CHOICE_OSMO_POOL="2. Create an osmosis pool"
CHOICE_SHIELDED_ACTION="3. Perform a shielded action"
CHOICE_BALANCE="4. Check your balances"
CHOICE_EXIT="5. Exit"

MENU_CHOICE=$(gum choose  --header "What would you like to do?" "$CHOICE_CONFIG" "$CHOICE_OSMO_POOL" "$CHOICE_SHIELDED_ACTION" "$CHOICE_BALANCE" "$CHOICE_EXIT")

if [ "$MENU_CHOICE" = "$CHOICE_CONFIG" ]; then
  echo "configurations"
elif [ "$MENU_CHOICE" = "$CHOICE_OSMO_POOL" ]; then
  echo "create a pool"
elif [ "$MENU_CHOICE" = "$CHOICE_SHIELDED_ACTION" ]; then
  echo "Do a shielded action"
elif [ "$MENU_CHOICE" = "$CHOICE_BALANCE" ]; then
  bash menu/balance.sh
elif [ "$MENU_CHOICE" = "$CHOICE_EXIT" ]; then
  exit 1
fi

# Menu should appear for a couple of things one could do.
# - Configuring some default values
# - Creating an osmosis pool
# - Doing a shielded swap

# - Checking balances for transparent/shielded address or osmosis address.
# It should also give a summary for the configured addresses. Perhaps give a dashboard already with the balances.
# Also create a button that could refresh the balances. Incorporate shielded sync into this with a locking mechanism to prevent corruption?