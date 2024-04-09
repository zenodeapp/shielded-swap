#!/bin/bash

# Menu
CHOICE_1="Perform a shielded swap from $NAM_DENOM to uosmo ($NAM_CHANNEL) [balance: 1000$NAM_DENOM]"
CHOICE_2="Perform a shielded swap from uosmo ($NAM_CHANNEL) to $NAM_DENOM [balance: 1000uosmo]"
CHOICE_BACK="Go back"

MENU_CHOICE=$(gum choose  --header "What type of shielded action would you like to perform?" "$CHOICE_1" "$CHOICE_2" "$CHOICE_BACK")

if [ "$MENU_CHOICE" = "$CHOICE_1" ]; then
  TOKEN_TO_TRANSFER="$NAM_DENOM"
elif [ "$MENU_CHOICE" = "$CHOICE_2" ]; then
  TOKEN_TO_TRANSFER=$NAM_UOSMO_DENOM
elif [ "$MENU_CHOICE" = "$CHOICE_BACK" ]; then
  bash layout/main.sh
fi