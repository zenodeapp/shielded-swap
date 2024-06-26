#!/bin/bash

# Always get latest config whenever we go into the main menu (the getter always makes sure the configs are valid)
source config/get.sh

# Menu
CHOICE_SHIELDED_ACTION="1. Perform a shielded action"
CHOICE_FUNDING="2. Fund your wallet(s)"
CHOICE_BALANCE="3. Check your balance(s)"
CHOICE_OSMO_POOL="4. Pool information"
CHOICE_CONFIG="5. Configuration"
CHOICE_EXIT="Exit"

MENU_CHOICE=$(gum choose  --header "What would you like to do?" "$CHOICE_SHIELDED_ACTION" "$CHOICE_FUNDING" "$CHOICE_BALANCE" "$CHOICE_OSMO_POOL" "$CHOICE_CONFIG" "$CHOICE_EXIT")

if [ "$MENU_CHOICE" = "$CHOICE_SHIELDED_ACTION" ]; then
  bash layout/shielded.sh
elif [ "$MENU_CHOICE" = "$CHOICE_FUNDING" ]; then
  bash layout/funding.sh
elif [ "$MENU_CHOICE" = "$CHOICE_BALANCE" ]; then
  bash layout/balance.sh
elif [ "$MENU_CHOICE" = "$CHOICE_OSMO_POOL" ]; then
  bash layout/pool.sh
elif [ "$MENU_CHOICE" = "$CHOICE_CONFIG" ]; then
  bash layout/config.sh
else
  exit 1
fi