#!/bin/bash

# Source shared functions
source helpers/shared.sh

# Source input functions
source helpers/input.sh

# Source set functions (also validates configurations)
source config/set.sh

# Create a temporary file and save all the current key-value pairs of the config.json file in a temporary file
CONFIG_TMP=".tmp/config.tmp"
rm $CONFIG_TMP 2>/dev/null

while IFS= read -r key; do
  CURRENT_VALUE="$key - $(jq -r ".$key" "$CONFIG_FILE")"
  echo "$CURRENT_VALUE" >> "$CONFIG_TMP"
done < "$KEYS_FILE"

# Give user all the editable choices
CONFIG_CHOICES=$(cat "$CONFIG_TMP" | gum filter --no-limit --header "Which values do you want to change? Use [TAB] or [CTRL+SPACE] to select multiple fields.")

# This usually happens when CTRL+C is pressed
if [ -z "$CONFIG_CHOICES" ]; then
  bash layout/config.sh
else
  # Initialize the keys and values arrays and only add the chosen configurations
  keys=()
  values=()
  while IFS='-' read -r key value; do
      key=$(echo "$key" | awk '{$1=$1};1')
      value=$(echo "$value" | awk '{$1=$1};1')

      keys+=("$key")
      values+=("$value")
  done <<< "$CONFIG_CHOICES"

  # Prompt user's input for each key-value pair
  keys_edited=()
  values_edited=()
  for ((i=0; i<${#keys[@]}; i++)); do
    key="${keys[$i]}"
    current_value="${values[$i]}"

    if [ ! -z "$key" ]; then
      # Prompt for a new value
      new_value=$(gum input --placeholder "Enter a new value for $key (default: $current_value)")

      # Update the key-value pair only if it's not empty
      if [ ! -z "$new_value" ]; then
        keys_edited+=("$key")
        values_edited+=("$new_value")
      fi
    fi
  done

  # If there are changes, prompt to save these.
  if [ ! ${#keys_edited[@]} -eq 0 ]; then
    # Show changes ready to be made
    echo "The following changes will be made:"
    print_key_pairs keys_edited values_edited

    # Confirm changes to be made
    gum confirm "Do you wish to proceed?" \
      && { modify_config_keys keys_edited values_edited; echo "Changes saved!"; } \
      || { echo "Changes canceled!"; }
  fi

  # Menu
  CHOICE_EDIT_MORE="Continue editing config.json"
  CHOICE_BACK="Back"

  MENU_CHOICE=$(gum choose  --header "What would you like to do?" "$CHOICE_EDIT_MORE" "$CHOICE_BACK")

  if [ "$MENU_CHOICE" = "$CHOICE_EDIT_MORE" ]; then
    bash layout/config-manual.sh
  else
    bash layout/config.sh
  fi
fi