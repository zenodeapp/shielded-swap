#!/bin/bash

# Menu
MENU_CHOICE=$(gum choose  --header "What would you like to do?" "Go back")
if [ "$MENU_CHOICE" = "Go back" ]; then
  bash menu/main.sh
fi