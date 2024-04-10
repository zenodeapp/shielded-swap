#!/bin/bash

# Source shared functions
source helpers/shared.sh

# Types of pool warnings
NO_POOL=$(gum style --padding "1 2" --margin "0" --border double --border-foreground 500 --foreground 500 "No pool id has been configured!")
NO_VALID_POOL=$(gum style --padding "1 2" --margin "0" --border double --border-foreground 600 --foreground 600 "No valid pool has been configured!")

if [ -z $OSMO_POOL_ID ]; then
  echo "$NO_POOL"
else
  POOL_INFO=$(get_osmosis_pool_json $OSMO_POOL_ID)
  if [ -z $POOL_INFO ]; then
    echo "$NO_VALID_POOL"
  else
    # Pool info
    DENOM0=$(get_osmosis_pool_info "$POOL_INFO" "denom0")
    DENOM1=$(get_osmosis_pool_info "$POOL_INFO" "denom1")
    AMOUNT1=$(get_osmosis_pool_info "$POOL_INFO" "amount1")
    DENOM2=$(get_osmosis_pool_info "$POOL_INFO" "denom2")
    AMOUNT2=$(get_osmosis_pool_info "$POOL_INFO" "amount2")
    POOL_ID=$(get_osmosis_pool_info "$POOL_INFO" "id")
    POOL_ADDRESS=$(get_osmosis_pool_info "$POOL_INFO" "address")
    SWAP_FEE=$(get_osmosis_pool_info "$POOL_INFO" "swap_fee")
    EXIT_FEE=$(get_osmosis_pool_info "$POOL_INFO" "exit_fee")
    
    # Pool block
    # If the denominators in the pool don't match the information in the config.json file, a warning is given.
    if ! { [ "$DENOM1" = "$NAM_IBC" ] && [ "$DENOM2" = "uosmo" ]; } && ! { [ "$DENOM1" = "uosmo" ] && [ "$DENOM2" = "$NAM_IBC" ]; }; then
      gum style --padding "1 2" --margin "0" --border double --border-foreground 1500 --foreground 1500 "> OSMOSIS POOL $OSMO_POOL_ID ($DENOM0)" \
        "$POOL_ADDRESS" \
        "This pool does not match an $(shorten_address $NAM_IBC) ($NAM_DENOM) - uosmo pair!"
    else
      gum style --padding "1 2" --margin "0" --border double --border-foreground 200 --foreground 200 "OSMOSIS POOL $OSMO_POOL_ID ($DENOM0)" \
        "$POOL_ADDRESS"
    fi
    
    # Denoms block
    BLOCK1=$(gum style --padding "1 2" --margin "0" --border normal --border-foreground 300 --foreground 300 " DENOM1" \ "$AMOUNT1 $DENOM1") 
    BLOCK2=$(gum style --padding "1 2" --margin "0" --border normal --border-foreground 800 --foreground 800 " DENOM2" \ "$AMOUNT2 $DENOM2") 
    gum join "$BLOCK1" "$BLOCK2"

    # Fee block
    gum style --padding "1 2" --margin "0" --border double --border-foreground 1900 --foreground 1900 "FEES" \
        "Swap fee: $SWAP_FEE" \
        "Exit fee: $EXIT_FEE"
  fi
fi

# Menu
CHOICE_CONFIG="1. Point to a different (existing) pool (edit config.json)"
CHOICE_OWN_POOL="1. Point to an existing pool you own"
CHOICE_CREATE_POOL="2. Create a new pool"
CHOICE_BACK="3. Go back"

MENU_CHOICE=$(gum choose  --header "What would you like to do?" "$CHOICE_CONFIG" "$CHOICE_OWN_POOL" "$CHOICE_CREATE_POOL" "$CHOICE_BACK")

if [ "$MENU_CHOICE" = "$CHOICE_CONFIG" ]; then
  bash layout/config.sh
elif [ "$MENU_CHOICE" = "$CHOICE_OWN_POOL" ]; then
  bash layout/pool-own.sh
elif [ "$MENU_CHOICE" = "$CHOICE_CREATE_POOL" ]; then
  bash layout/pool-create.sh
elif [ "$MENU_CHOICE" = "$CHOICE_BACK" ]; then
  bash layout/main.sh
fi