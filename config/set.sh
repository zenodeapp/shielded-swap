#!/bin/bash

# Always validate before using configurations
source config/validate.sh

# Modify a single key value in the config file
modify_config_key() {
  KEY="$1"
  VALUE="$2"
  
  if [ ! -z "$KEY" ]; then
    # booleans and numbers should be saved using --argjson to not encapsulate them as a string
    if [[ "$VALUE" =~ ^[0-9]+([.][0-9]+)?$ || "$VALUE" = "true" || "$VALUE" = "false" ]]; then
      jq --arg key "$KEY" --argjson value "$VALUE" '.[$key] = $value' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    else
      jq --arg key "$KEY" --arg value "$VALUE" '.[$key] = $value' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    fi
  fi
}

# Modify multiple key values in the config file
modify_config_keys() {
  local -n KEYS=$1
  local -n VALUES=$2
  
  for ((i=0; i<${#keys[@]}; i++)); do
    KEY="${KEYS[$i]}"
    VALUE="${VALUES[$i]}"
    modify_config_key "$KEY" "$VALUE"
  done
}