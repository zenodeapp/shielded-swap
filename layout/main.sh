#!/bin/bash

# Menu should appear for a couple of things one could do.
# - Configuring some default values
# - Creating an osmosis pool
# - Doing a shielded swap
# - Checking balances for transparent/shielded address or osmosis address.

# It should also give a summary for the configured addresses. Perhaps give a dashboard already with the balances.
# Also create a button that could refresh the balances. Incorporate shielded sync into this with a locking mechanism to prevent corruption?

# Always get latest config whenever we go into the main menu (the getter always makes sure the configs are valid)
source config/get.sh

# Menu
CHOICE_SHIELDED_ACTION="1. Perform a shielded action"
CHOICE_BALANCE="2. Check your balance(s)"
CHOICE_OSMO_POOL="3. Pool information"
CHOICE_CONFIG="4. Configuration"
CHOICE_EXIT="5. Exit"

MENU_CHOICE=$(gum choose  --header "What would you like to do?" "$CHOICE_SHIELDED_ACTION" "$CHOICE_BALANCE" "$CHOICE_OSMO_POOL" "$CHOICE_CONFIG" "$CHOICE_EXIT")

if [ "$MENU_CHOICE" = "$CHOICE_SHIELDED_ACTION" ]; then
  bash layout/shielded.sh
elif [ "$MENU_CHOICE" = "$CHOICE_BALANCE" ]; then
  bash layout/balance.sh
elif [ "$MENU_CHOICE" = "$CHOICE_OSMO_POOL" ]; then
  bash layout/pool.sh
elif [ "$MENU_CHOICE" = "$CHOICE_CONFIG" ]; then
  bash layout/config.sh
elif [ "$MENU_CHOICE" = "$CHOICE_EXIT" ]; then
  exit 1
fi