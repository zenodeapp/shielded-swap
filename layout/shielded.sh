#!/bin/bash

# Source shared functions
source helpers/shared.sh

# Source input functions
source helpers/input.sh

# Variables
MIN_UOSMO=1000000
MIN_NAM=10

if [ "$SHIELDED_BROKEN" = 'true' ]; then
  START_ADDRESS="$NAM_TRANSPARENT"
else
  START_ADDRESS="$NAM_VIEWING_KEY"
fi

### MENU ###
CHOICE_1="Perform a shielded swap from $NAM_DENOM => uosmo ($NAM_CHANNEL)"
CHOICE_2="Perform a shielded swap from uosmo ($NAM_CHANNEL) => $NAM_DENOM"
CHOICE_BACK="Go back"

MENU_CHOICE=$(gum choose  --header "What type of shielded action would you like to perform?" "$CHOICE_1" "$CHOICE_2" "$CHOICE_BACK")

if [ "$MENU_CHOICE" = "$CHOICE_1" ]; then
  TOKEN_TO_TRANSFER="$NAM_DENOM"
  TOKEN_TO_RECEIVE="$NAM_UOSMO_DENOM"
  SENDING_NAM=true
elif [ "$MENU_CHOICE" = "$CHOICE_2" ]; then
  TOKEN_TO_TRANSFER="$NAM_UOSMO_DENOM"
  TOKEN_TO_RECEIVE="$NAM_DENOM"
  SENDING_NAM=false
elif [ "$MENU_CHOICE" = "$CHOICE_BACK" ]; then
  bash layout/main.sh
fi



### CHECK BALANCES ###
# Before we can swap we need to make sure that we have enough uosmo on osmosis and enough naan on namada
header_block "BALANCE CHECK"

# Check osmosis balance
gum spin --show-output --title "Checking balance on $OSMO_ADDRESS..." sleep 2
OSMOSIS_BALANCE=$(get_osmosis_balance "uosmo")

if [ "$(number_is_ge $OSMOSIS_BALANCE $MIN_UOSMO)" = "true" ]; then
  gum log --structured --level info "Found $OSMOSIS_BALANCE uosmo."
else
  gum log --structured --level error "You currently have $OSMOSIS_BALANCE uosmo; you need to have at least a minimum of $MIN_UOSMO uosmo!"
fi

# Check namada balance
gum spin --show-output --title "Checking balance on $START_ADDRESS..." sleep 2
NAM_BALANCE=$(get_namada_balance $NAM_DENOM)

if [ "$(number_is_ge $NAM_BALANCE $MIN_NAM)" = "true" ]; then
  gum log --structured --level info "Found $NAM_BALANCE $NAM_DENOM."
else
  gum log --structured --level error "You currently have $NAM_BALANCE $NAM_DENOM; you need to have at least a minimum of $MIN_NAM $NAM_DENOM!"
fi

if [ "$(number_is_ge $OSMOSIS_BALANCE $MIN_UOSMO)" = "true" ] && [ "$(number_is_ge $NAM_BALANCE $MIN_NAM)" = "true" ]; then
  echo_success "Enough balance found on both addresses!"
  
  # Before asking how much to transfer, calculate the max one can send
  if $SENDING_NAM; then # No need to recalculate balance here since it's naan
    BALANCE_AVAILABLE=$(bc <<< "$NAM_BALANCE - 5") # have a minimum of ~5 NAAN available
  else
    # TODO: fix for the other way around
        # gum spin --title "Checking $TOKEN_TO_TRANSFER balance on $START_ADDRESS..." sleep 2
    # if [ "$SHIELDED_BROKEN" = "true" ]; then
    #   BALANCE_AVAILABLE=$(get_namada_balance $TOKEN_TO_TRANSFER)
    # else
    #   BALANCE_AVAILABLE=$(get_namada_shielded_balance $TOKEN_TO_TRANSFER)
    # fi
    gum log --structured --level info "Found $BALANCE_AVAILABLE $TOKEN_TO_TRANSFER."
  fi

  # if balance available higher than 0
  if [ $(bc <<< "$BALANCE_AVAILABLE > 0") -eq 1 ]; then
    AMOUNT_TO_TRANSFER=$(repeat_input_number_max "How much $TOKEN_TO_TRANSFER would you like to swap for $TOKEN_TO_RECEIVE? [max: $BALANCE_AVAILABLE]" "$BALANCE_AVAILABLE" "false")
    SLIPPAGE=$(repeat_input_number_max "What should the slippage be set to? [default: 2%; max: 49%]" "49")
    
    # Defaults to 2% if no value is set
    if [ -z "$SLIPPAGE" ]; then
      SLIPPAGE=2
    fi

    # Simulate a swap and tell how much the user will receive
    ESTIMATE_AMOUNT=$(estimate_swap_amount "$NAM_IBC" "$AMOUNT_TO_TRANSFER")
    ESTIMATE_AMOUNT_MIN=$(calculate_slippage_amount "$ESTIMATE_AMOUNT" "$SLIPPAGE")
    
    gum log --structured --level info "In: $AMOUNT_TO_TRANSFER $TOKEN_TO_TRANSFER (slippage set to $SLIPPAGE%)"
    gum log --structured --level info "Out: approx. $ESTIMATE_AMOUNT_MIN ~ $ESTIMATE_AMOUNT $TOKEN_TO_RECEIVE."
    CONFIRM_SWAP=$(gum confirm "You will receive a minimum of $ESTIMATE_AMOUNT_MIN $TOKEN_TO_RECEIVE, do you want to continue?" && echo "true" || echo "false")

    if [ "$CONFIRM_SWAP" = "true" ]; then
      gum spin --title "Checking balance for $NAM_IBC on $OSMO_ADDRESS..." sleep 2

      # Check balance on osmosis side
      if $SENDING_NAM; then
        gum spin --title "Checking balance for $NAM_IBC on $OSMO_ADDRESS..." sleep 2
        BALANCE_TARGET=$(get_osmosis_balance "$NAM_IBC")
        BALANCE_TARGET_COUNTER="$OSMOSIS_BALANCE"
        gum log --structured --level info "Found $BALANCE_TARGET $NAM_IBC."
      else
        BALANCE_TARGET="$OSMOSIS_BALANCE"
        BALANCE_TARGET_COUNTER=$(get_osmosis_balance "$NAM_IBC")
        gum log --structured --level info "Found $BALANCE_TARGET uosmo."
      fi

      # Send the tokens from namada to osmosis
      gum spin --show-output --title "Transferring $AMOUNT_TO_TRANSFER $TOKEN_TO_TRANSFER over IBC to $OSMO_ADDRESS..." sleep 2
      transfer_ibc_namada "$OSMO_ADDRESS" "$TOKEN_TO_TRANSFER" "$AMOUNT_TO_TRANSFER"

      # Check if token got transferred
      if $SENDING_NAM; then
        BALANCE_RECEIVER=$(loop_check_balance_osmosis "$NAM_IBC" "$BALANCE_TARGET" "$AMOUNT_TO_TRANSFER")
      else
        BALANCE_RECEIVER=$(loop_check_balance_osmosis "uosmo" "$BALANCE_TARGET" "$AMOUNT_TO_TRANSFER")
      fi

      if [ -z "$BALANCE_RECEIVER" ]; then
        echo_fail "Transaction timed out...no $TOKEN_TO_TRANSFER was received on $(shorten_address $OSMO_ADDRESS 6 6 38)."
        bash layout/main.sh
      else
        echo_success "$AMOUNT_TO_TRANSFER $TOKEN_TO_TRANSFER received. Balance on $(shorten_address $START_ADDRESS 6 6 38) is now $BALANCE_RECEIVER $TOKEN_TO_TRANSFER!"
        
        # Swap the tokens on the osmosis chain
        gum spin --show-output --title "Swapping $AMOUNT_TO_TRANSFER $TOKEN_TO_TRANSFER for $ESTIMATE_AMOUNT_MIN ~ $ESTIMATE_AMOUNT $TOKEN_TO_RECEIVE..." sleep 2
        swap_exact_amount_in "$NAM_IBC" "$AMOUNT_TO_TRANSFER" "$ESTIMATE_AMOUNT_MIN"

        # Check that you got the tokens and see how many
        if $SENDING_NAM; then
          BALANCE_RECEIVER=$(loop_check_balance_osmosis "uosmo" "$BALANCE_TARGET_COUNTER" "$AMOUNT_TO_TRANSFER")
        else
          BALANCE_RECEIVER=$(loop_check_balance_osmosis "$NAM_IBC" "$BALANCE_TARGET_COUNTER" "$AMOUNT_TO_TRANSFER")
        fi

        if [ -z "$BALANCE_RECEIVER" ]; then
          echo_fail "Transaction timed out...no $TOKEN_TO_TRANSFER got swapped on $(shorten_address $OSMO_ADDRESS 6 6 38)."
          bash layout/main.sh
        else
          BALANCE_DIFF=$(bc <<< "$BALANCE_RECEIVER - $BALANCE_TARGET_COUNTER")
          echo_success "$AMOUNT_TO_TRANSFER $TOKEN_TO_TRANSFER got swapped for $BALANCE_DIFF $TOKEN_TO_RECEIVE on osmosis!"
          
          # generate IBC and send back to shielded address
          # echo "Generating IBC memo..."
# IBC_MEMO=$(gen_ibc_memo "$shielded_namada_address" "uosmo" "$AMOUNT_RECEIVED") # call with naan if we do it the other way around
# echo "Generated: $IBC_MEMO"
          # shielded sync after a minute or two or give user option to keep chevking their sddrrds

          # Show balance
        fi
      fi
    else
      echo_fail "Swap got canceled."
      bash layout/main.sh
    fi
  else
    echo_fail "You can't continue doing a shielded swap for not having enough $TOKEN_TO_TRANSFER on $(shorten_address $START_ADDRESS 6 6 38)!"
    bash layout/main.sh
  fi
else
  echo_fail "You can't continue doing a shielded swap for not having enough balance!"
  bash layout/main.sh
fi