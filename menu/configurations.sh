#!/bin/bash

# CONFIG_NAM=".nam (value: $NAM)"
# CONFIG_NAM_IBC=".namIbc (value: $NAM_IBC)"
# CONFIG_NAM_CHANNEL=".namChannel (value: $NAM_CHANNEL)"
# CONFIG_OSMO_CHANNEL=".osmoChannel (value: $OSMO_CHANNEL)"
# CONFIG_OSMO_POOL_ID=".osmoPoolId (value: $OSMO_POOL_ID)"
# CONFIG_NAM_RPC=".namRpc (value: $NAM_RPC)"
# CONFIG_OSMO_RPC=".osmoRpc (value: $OSMO_RPC)"
# CONFIG_NAM_TRANSPARENT=".addresses.namTransparent (value: $NAM_TRANSPARENT)"
# CONFIG_NAM_SHIELDED=".addresses.namShielded (value: $NAM_SHIELDED)"
# CONFIG_NAM_VIEWING_KEY=".addresses.namViewingKey (value: $NAM_VIEWING_KEY)"
# CONFIG_OSMO_ADDRESS=".addresses.osmoAddress (value: $OSMO_ADDRESS)"
# CONFIG_SHIELDED_BROKEN=".addresses.shieldedBroken (value: $SHIELDED_BROKEN)"

# CONFIG_NAM=".nam"
# CONFIG_NAM_IBC=".namIbc"
# CONFIG_NAM_CHANNEL=".namChannel"
# CONFIG_OSMO_CHANNEL=".osmoChannel"
# CONFIG_OSMO_POOL_ID=".osmoPoolId"
# CONFIG_NAM_RPC=".namRpc"
# CONFIG_OSMO_RPC=".osmoRpc"
# CONFIG_NAM_TRANSPARENT=".addresses.namTransparent (value: $NAM_TRANSPARENT)"
# CONFIG_NAM_SHIELDED=".addresses.namShielded (value: $NAM_SHIELDED)"
# CONFIG_NAM_VIEWING_KEY=".addresses.namViewingKey (value: $NAM_VIEWING_KEY)"
# CONFIG_OSMO_ADDRESS=".addresses.osmoAddress (value: $OSMO_ADDRESS)"
# CONFIG_SHIELDED_BROKEN=".addresses.shieldedBroken (value: $SHIELDED_BROKEN)"

# Assuming config.json is your JSON file
config_file="config/config.json"

prompt_change() {
  keys="$1"
  local new_values=()

  for ((i=0; i<${#keys[@]}; i++)); do
    key=${keys[$i]}
    current_value=$(jq -r "$key" "$config_file")

    new_value=$(gum input --placeholder "Enter a new value for $key (current: $current_value)")

    new_values["$key"]="$new_value"
  done

  echo "Summary of changes:"
  for key in "${!new_values[@]}"; do
      echo "  $key: ${new_values[$key]}"
  done
}

# Define the filename for the modified lines
output_file="config/modified_config.txt"
rm $output_file

# Loop through each line in the file
while IFS= read -r line; do
    # Append " - the_value_for_this_key" to the line
    new_line="$line - $(jq -r "$line" "$config_file")"
    # Output the modified line to the output file
    echo "$new_line" >> "$output_file"
done < "config/config.txt"

CONFIG_CHOICES=$(cat config/modified_config.txt | gum filter --no-limit --header "Which values do you want to change? Use [TAB] or [CTRL+SPACE] to select multiple fields.")

echo "$CONFIG_CHOICES"

# Initialize arrays for keys and values
keys=()
values=()

# Read each line and split into key and value
while IFS='-' read -r key value; do
    # Trim leading and trailing whitespace from key and value
    key=$(echo "$key" | awk '{$1=$1};1')
    value=$(echo "$value" | awk '{$1=$1};1')

    # Add key and value to arrays
    keys+=("$key")
    values+=("$value")
done <<< "$CONFIG_CHOICES"

# Prompt for new values for each key-value pair
for ((i=0; i<${#keys[@]}; i++)); do
    key="${keys[$i]}"
    current_value="${values[$i]}"

    # Prompt for a new value
    new_value=$(gum input --placeholder "Enter a new value for $key (current: $current_value)")

    # Update the values array with the new value
    values[$i]="$new_value"
done

# Print updated key-value pairs
for ((i=0; i<${#keys[@]}; i++)); do
    echo "${keys[$i]} - ${values[$i]}"
done


# Function to save configurations using jq
save_configs() {
    for ((i=0; i<${#keys[@]}; i++)); do
        key="${keys[$i]}"
        value="${values[$i]}"
        jq --arg key "${key:1}" --arg value "$value" '.[$key] = $value' "$config_file" > temp.json && mv temp.json "$config_file"
    done
}

gum confirm "Are you sure you want to change the values?" && { save_configs; echo "Changes saved."; } || echo "Changes canceled."

# Menu
MENU_CHOICE=$(gum choose  --header "What would you like to do?" "Go back")
if [ "$MENU_CHOICE" = "Go back" ]; then
  bash menu/main.sh
fi