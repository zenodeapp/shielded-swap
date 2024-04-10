#!/bin/bash

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