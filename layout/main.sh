#!/bin/bash

# Menu should appear for a couple of things one could do.
# - Configuring some default values
# - Creating an osmosis pool
# - Doing a shielded swap
# - Checking balances for transparent/shielded address or osmosis address.

# It should also give a summary for the configured addresses. Perhaps give a dashboard already with the balances.
# Also create a button that could refresh the balances. Incorporate shielded sync into this with a locking mechanism to prevent corruption?

# Source shared functions
source helpers/shared.sh

# Always get latest config whenever we go into the main menu (the getter always makes sure the configs are valid)
source config/get.sh

# Greeting
if [ $SHIELDED_BROKEN = 'true' ]; then
  if [ -z $NAM_TRANSPARENT ]; then
    echo "Welcome, stranger!"
  else
    echo "Welcome, $(shorten_address $NAM_TRANSPARENT 21 21)!"
  fi
else
  if [ -z $NAM_VIEWING_KEY ]; then
    echo "Welcome, anonymous stranger!"
  else
    echo "Welcome, $(shorten_address $NAM_VIEWING_KEY 21 21)!"
  fi
fi

# Menu
CHOICE_CONFIG="1. Configurations"
CHOICE_OSMO_POOL="2. Create an osmosis pool"
CHOICE_SHIELDED_ACTION="3. Perform a shielded action"
CHOICE_BALANCE="4. Check your balances"
CHOICE_EXIT="5. Exit"

MENU_CHOICE=$(gum choose  --header "What would you like to do?" "$CHOICE_CONFIG" "$CHOICE_OSMO_POOL" "$CHOICE_SHIELDED_ACTION" "$CHOICE_BALANCE" "$CHOICE_EXIT")

if [ "$MENU_CHOICE" = "$CHOICE_CONFIG" ]; then
  bash layout/config.sh
elif [ "$MENU_CHOICE" = "$CHOICE_OSMO_POOL" ]; then
  bash layout/pool.sh
elif [ "$MENU_CHOICE" = "$CHOICE_SHIELDED_ACTION" ]; then
  bash layout/shielded.sh
elif [ "$MENU_CHOICE" = "$CHOICE_BALANCE" ]; then
  bash layout/balance.sh
elif [ "$MENU_CHOICE" = "$CHOICE_EXIT" ]; then
  exit 1
fi