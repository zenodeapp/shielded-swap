#!/bin/bash

# Shorten an address, eth-style
shorten_address() {
  ADDRESS="$1"
  FIRST_LENGTH="${2:-6}"
  LAST_LENGTH="${3:-6}"
  MAX_LENGTH="${4:-45}"

  if (( ${#ADDRESS} > MAX_LENGTH )); then
    FIRST_PART="${ADDRESS:0:FIRST_LENGTH}"
    LAST_PART="${ADDRESS: -LAST_LENGTH}"
    echo "$FIRST_PART...$LAST_PART"
  else
    echo "$ADDRESS"
  fi
}

# Printing an array (of keys)
print_array() {
  local -n ARRAY=$1

  echo "$ARRAY"
  
  for ITEM in "${ARRAY[@]}"; do
    echo "$ITEM"
  done
}

# Printing two arrays (for keys and values)
print_key_pairs() {
  local -n KEYS=$1
  local -n VALUES=$2
  
  for ((i=0; i<${#KEYS[@]}; i++)); do
    echo "${KEYS[$i]} - ${VALUES[$i]}"
  done
}

# This keeps asking for a number as input, empty values are okay
repeat_input_number() {
  PROMPT="$1"
  INPUT=""
  
  while true; do
    INPUT=$(gum input --placeholder "$PROMPT")
    
    if [ -z "$INPUT" ]; then
      break
    fi

    # Check if the input is a valid number
    if [[ ! "$INPUT" =~ ^[0-9]+$ ]]; then
      gum log --structured --level error "Invalid input! Please enter a valid number."
      continue
    fi

    break
  done

  echo "$INPUT"
}

# This keeps asking for a ratio as input, empty values are okay
repeat_input_ratio() {
  local PROMPT="$1"
  local INPUT
  
  while true; do
    INPUT=$(gum input --placeholder "$PROMPT")
    
    if [ -z "$INPUT" ]; then
      break
    fi

    # Check if the input is in the format "number:number"
    if [[ ! "$INPUT" =~ ^[0-9]+:[0-9]+$ ]]; then
      gum log --structured --level error "Invalid input format! Please enter in the format 'number:number'."
      continue
    fi
    break
  done

  echo "$INPUT"
}