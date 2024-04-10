#!/bin/bash

# Function to handle Ctrl+C
ctrl_c() {
    echo "Ctrl+C detected. Exiting..."
    exit 1
}

# Set up trap for SIGINT (Ctrl+C)
trap ctrl_c SIGINT

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

# This keeps asking for a number as input, when $2 is 'false' it will force the user to give an answer
repeat_input_number() {
  PROMPT="$1"
  ALLOW_EMPTY=${2:-"true"}
  INPUT=""
  
  while true; do
    INPUT=$(gum input --placeholder "$PROMPT")
    
    if [ "$ALLOW_EMPTY" = "true" ] && [ -z "$INPUT" ]; then
      break
    fi

   # Check if the input is a valid number (integer or float)
    if [[ ! "$INPUT" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
      gum log --structured --level error "Invalid input! Please enter a valid number."
      continue
    fi

    break
  done

  echo "$INPUT"
}

# This keeps asking for a number as input, also checks if it's not higher than the max given.
# when $3 is 'false' it will force the user to give an answer
repeat_input_number_max() {
  PROMPT="$1"
  MAX=$2
  ALLOW_EMPTY=${3:-"true"}
  INPUT=""

  while true; do
    INPUT=$(gum input --placeholder "$PROMPT")
    
    if [ "$ALLOW_EMPTY" = "true" ] && [ -z "$INPUT" ]; then
      break
    fi

    # Check if the input is a valid number (integer or float)
    if [[ ! "$INPUT" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
      gum log --structured --level error "Invalid input! Please enter a valid number."
      continue
    fi

    # Check if input is higher than the given max
    if (( $(bc <<< "$INPUT > $MAX") )); then
      gum log --structured --level error "Input exceeds maximum value! Please enter a number less than or equal to $MAX."
      continue
    fi

    break
  done

  echo "$INPUT"
}

# This keeps asking for a ratio as input, when $2 is 'false' it will force the user to give an answer
repeat_input_ratio() {
  PROMPT="$1"
  ALLOW_EMPTY=${2:-"true"}
  INPUT=""
  
  while true; do
    INPUT=$(gum input --placeholder "$PROMPT")
    
    if [ "$ALLOW_EMPTY" = "true" ] && [ -z "$INPUT" ]; then
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

# Function to check if a number is greater or equal to the given minimum value
number_is_ge() {
  NUMBER=$1
  MINIMUM=$2

  if [[ $NUMBER =~ ^[0-9]+(\.[0-9]+)?$ && $(bc <<< "$NUMBER >= $MINIMUM") -eq 1 ]]; then
    echo "true"
  else
    echo "false"
  fi
}

# Success echo
echo_success() {
  MESSAGE=$1
  
  echo ":heavy_check_mark:  $MESSAGE" | gum format -t emoji
}

# Fail echo
echo_fail() {
  MESSAGE=$1
  
  echo ":x: $MESSAGE" | gum format -t emoji
}

# Reusable block with double border and padding
header_block() {
  HEADING="$1"
  COLOR=${3:-1500}

  gum style --padding "1 2" --margin "0" --border double --border-foreground $COLOR --foreground $COLOR "$HEADING"
}