#!/bin/bash

CHOICE_BACK="Go back"

MENU_CHOICE=$(gum choose  --header "What would you like to do?" "$CHOICE_BACK")

if [ "$MENU_CHOICE" = "$CHOICE_BACK" ]; then
  bash layout/main.sh
fi