#!/bin/bash

# Source shared functions
source helpers/shared.sh

# Source input functions
source helpers/input.sh

# Source set functions (also validates configurations)
source config/set.sh

# Menu
CHOICE_EDIT="1. Edit config.json"
CHOICE_CREATE_KEYS="2. Create keys"
CHOICE_BACK="Back"

MENU_CHOICE=$(gum choose  --header "What would you like to do?" "$CHOICE_EDIT" "$CHOICE_CREATE_KEYS" "$CHOICE_BACK")

if [ "$MENU_CHOICE" = "$CHOICE_EDIT" ]; then
  bash layout/config-manual.sh
elif [ "$MENU_CHOICE" = "$CHOICE_CREATE_KEYS" ]; then
  bash layout/config-keys.sh
else
  bash layout/main.sh
fi