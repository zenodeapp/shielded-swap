#!/bin/bash

# Source shared functions
source helpers/shared.sh

# Source input functions
source helpers/input.sh

# Variables

# DENOM1 is always nam/naan, DENOM2 is uosmo. 
# NOTE: For now this is the only pair possible, but could be refactored into allowing all sorts of pairs.
# Will do this if I have enough time at hand.
DENOM1_NAMADA="$NAM_DENOM"
DENOM1_OSMOSIS="$NAM_IBC"
DENOM2_NAMADA="$NAM_UOSMO_DENOM"
DENOM2_OSMOSIS="uosmo"

# This is temporarily for 'fixing' the IBC shielded transfer on SE
if [ "$SHIELDED_BROKEN" = 'true' ]; then
  NAM_ADDRESS="$NAM_TRANSPARENT"
else
  NAM_ADDRESS="$NAM_VIEWING_KEY"
fi

# Menu
CHOICE_1="Perform a shielded swap from $DENOM1_NAMADA => $DENOM2_OSMOSIS ($NAM_CHANNEL)"
CHOICE_2="Perform a shielded swap from $DENOM2_OSMOSIS ($NAM_CHANNEL) => $DENOM1_NAMADA"
CHOICE_BACK="Go back"

MENU_CHOICE=$(gum choose  --header "What type of shielded action would you like to perform?" "$CHOICE_1" "$CHOICE_2" "$CHOICE_BACK")

# Make DENOM1 uosmo and DENOM2 naan/nam instead if we are doing the reverted swap
if [ "$MENU_CHOICE" = "$CHOICE_1" ]; then
  SENDING_NAM=true
elif [ "$MENU_CHOICE" = "$CHOICE_2" ]; then
  SENDING_NAM=false
  DENOM1_NAMADA="$NAM_UOSMO_DENOM"
  DENOM1_OSMOSIS="uosmo"
  DENOM2_NAMADA="$NAM_DENOM"
  DENOM2_OSMOSIS="$NAM_IBC"
elif [ "$MENU_CHOICE" = "$CHOICE_BACK" ]; then
  bash layout/main.sh
fi

### CHECK BALANCES ###
# Before we can swap we need to make sure that we have enough uosmo on osmosis and enough naan on namada
header_block "BALANCE CHECK"

# Function to check balance and log errors if balance is below minimum
check_balance() {
  TOKEN="$1"
  BALANCE="$2"
  MIN_BALANCE="$3"
  
  if [ "$(number_is_ge "$BALANCE" "$MIN_BALANCE")" = "true" ]; then
    gum log --structured --level info "Found $BALANCE $TOKEN."
    echo "true"
  else
    gum log --structured --level error "You currently have $BALANCE $TOKEN; you need to have at least a minimum of $MIN_BALANCE $TOKEN!"
    echo "false"
  fi
}

# Check uosmo balance on osmosis
gum spin --show-output --title "Checking balance on $(shorten_address $OSMO_ADDRESS)..." sleep 2
MIN_UOSMO=1000000
OSMOSIS_UOSMO_BALANCE=$(get_osmosis_balance "uosmo")
OSMOSIS_UOSMO_BALANCE_VALID=$(check_balance "uosmo" "$OSMOSIS_UOSMO_BALANCE" "$MIN_UOSMO")

# Check naan/nam balance on namada
gum spin --show-output --title "Checking balance on $(shorten_address $NAM_ADDRESS 19 19)..." sleep 2
MIN_NAM=10
NAMADA_NAM_BALANCE=$(get_namada_balance "$NAM_DENOM")
NAMADA_NAM_BALANCE_VALID=$(check_balance "$NAM_DENOM" "$NAMADA_NAM_BALANCE" "$MIN_NAM")

# Before asking how much to transfer, calculate the max one can send
if $SENDING_NAM; then # No need to recalculate balance here since it's naan
  if [ "$NAMADA_NAM_BALANCE_VALID" = "true" ]; then
    BALANCE_AVAILABLE=$(bc <<< "$NAMADA_NAM_BALANCE - 5") # have a minimum of ~5 NAAN available to play it safe
    BALANCE_AVAILABLE_VALID="true"
  fi
else
  # We have to calculate the minimum needed for a successful swap
  MIN_DENOM2=$(estimate_swap_amount "$DENOM2_OSMOSIS" "2")
  gum spin --show-output --title "Checking balance of "$DENOM1_NAMADA" on $(shorten_address $NAM_ADDRESS 19 19)..." sleep 2
  BALANCE_AVAILABLE=$(get_namada_balance "$DENOM1_NAMADA")
  BALANCE_AVAILABLE_VALID=$(check_balance "$DENOM1_NAMADA" "$BALANCE_AVAILABLE" "$MIN_DENOM2")
fi

# Check if all balances are valid
if [ "$OSMOSIS_UOSMO_BALANCE_VALID" = "true" ] && [ "$NAMADA_NAM_BALANCE_VALID" = "true" ] && [ "$BALANCE_AVAILABLE_VALID" = "true" ]; then
  echo_success "Enough balance found on both addresses!"
  ### SWAP PREVIEW ###
  # Before we can start the process we'll preview the swap
  header_block "SWAP PREVIEW"

  # User input
  AMOUNT_TO_TRANSFER=$(repeat_input_number_max "How much $DENOM1_NAMADA would you like to swap for $DENOM2_NAMADA? [max: $BALANCE_AVAILABLE]" "$BALANCE_AVAILABLE" "false")
  SLIPPAGE=$(repeat_input_number_max "What should the slippage be set to? [default: 2%; max: 49%]" "49")
  
  # Defaults to 2% if no value is set
  if [ -z "$SLIPPAGE" ]; then
    SLIPPAGE=2
  fi

  # Simulate a swap and tell how much the user will receive
  ESTIMATE_AMOUNT=$(estimate_swap_amount "$DENOM1_OSMOSIS" "$AMOUNT_TO_TRANSFER")
  
  ESTIMATE_AMOUNT_MIN=$(calculate_slippage_amount "$ESTIMATE_AMOUNT" "$SLIPPAGE")
  
  if ! { [ "$ESTIMATE_AMOUNT" = "0" ] || [ "$ESTIMATE_AMOUNT_MIN" = "0" ]; }; then
    # Swap preview blocks
    BLOCK1=$(gum style --padding "1 2" --margin "0" --border normal --border-foreground 300 --foreground 300 " GIVE" \ "$AMOUNT_TO_TRANSFER" \ "$DENOM1_NAMADA") 
    BLOCK2=$(gum style --padding "1 2" --margin "0" --border normal --border-foreground 800 --foreground 800 " RECEIVE" \ "$ESTIMATE_AMOUNT_MIN ~ $ESTIMATE_AMOUNT" \ "$DENOM2_NAMADA") 
    gum join "$BLOCK1" "$BLOCK2"

    CONFIRM_SWAP=$(gum confirm "You will receive a minimum of $ESTIMATE_AMOUNT_MIN $DENOM2_NAMADA (slippage: $SLIPPAGE%), do you want to continue?" && echo "true" || echo "false")

    if [ "$CONFIRM_SWAP" = "true" ]; then
      ### FROM NAMADA => OSMOSIS ###
      header_block "NAMADA => OSMOSIS"
      
      # Check balance on osmosis side
      gum spin --show-output --title "Checking balance for $DENOM1_OSMOSIS on $(shorten_address $OSMO_ADDRESS)..." sleep 2
      BALANCE_TARGET=$(get_osmosis_balance "$DENOM1_OSMOSIS")
      BALANCE_TARGET_COUNTER=$(get_osmosis_balance "$DENOM2_OSMOSIS")
      gum log --structured --level info "Found $BALANCE_TARGET $DENOM1_OSMOSIS."

      # Send the tokens from namada to osmosis
      gum spin --show-output --title "Transferring $AMOUNT_TO_TRANSFER $DENOM1_NAMADA from $(shorten_address $NAM_ADDRESS 19 19) over IBC to $(shorten_address $OSMO_ADDRESS)..." sleep 2
      transfer_ibc_namada "$OSMO_ADDRESS" "$DENOM1_NAMADA" "$AMOUNT_TO_TRANSFER"

      # Check if token got transferred
      BALANCE_RECEIVER=$(loop_check_balance_osmosis "$DENOM1_OSMOSIS" "$BALANCE_TARGET" "$AMOUNT_TO_TRANSFER")

      if [ -z "$BALANCE_RECEIVER" ]; then
        echo_fail "Transaction timed out...no $DENOM1_OSMOSIS was received on $(shorten_address $OSMO_ADDRESS 6 6 38)."
        bash layout/main.sh
      else
        echo_success "$AMOUNT_TO_TRANSFER $DENOM1_OSMOSIS received. Balance on $(shorten_address $OSMO_ADDRESS 6 6 38) is now $BALANCE_RECEIVER $DENOM1_OSMOSIS!"
        
        ### SWAP ON OSMOSIS CHAIN ###
        header_block "SWAP ON OSMOSIS"

        gum spin --show-output --title "Swapping $AMOUNT_TO_TRANSFER $DENOM1_OSMOSIS for $ESTIMATE_AMOUNT_MIN ~ $ESTIMATE_AMOUNT $DENOM2_OSMOSIS..." sleep 2
        swap_exact_amount_in "$DENOM1_OSMOSIS" "$AMOUNT_TO_TRANSFER" "$ESTIMATE_AMOUNT_MIN"

        # Check that you got the tokens and see how many
        BALANCE_RECEIVER=$(loop_check_balance_osmosis "$DENOM2_OSMOSIS" "$BALANCE_TARGET_COUNTER" "$AMOUNT_TO_TRANSFER")

        if [ -z "$BALANCE_RECEIVER" ]; then
          echo_fail "Transaction timed out...no $DENOM1_OSMOSIS got swapped on $(shorten_address $OSMO_ADDRESS 6 6 38)."
          bash layout/main.sh
        else
          BALANCE_DIFF=$(bc <<< "$BALANCE_RECEIVER - $BALANCE_TARGET_COUNTER")
          echo_success "$AMOUNT_TO_TRANSFER $DENOM1_OSMOSIS got swapped for $BALANCE_DIFF $DENOM2_OSMOSIS on osmosis!"
          
            ### SEND BACK TO NAMADA ###
          header_block "SEND BACK TO NAMADA"
          gum spin --show-output --title "Preparing IBC memo for transfer back..." sleep 2
          IBC_MEMO=$(gen_ibc_memo "$NAM_SHIELDED" "$DENOM2_OSMOSIS" "$BALANCE_DIFF")
          gum log --structured --level info "Generated: $IBC_MEMO."

          gum spin --show-output --title "Sending $BALANCE_DIFF $DENOM2_OSMOSIS to $(shorten_address $NAM_SHIELDED)..." sleep 2
          transfer_ibc_osmosis "$NAM_SHIELDED" "$DENOM2_OSMOSIS" "$BALANCE_DIFF" "$IBC_MEMO"

          # End of swap
          echo_success "$AMOUNT_TO_TRANSFER $DENOM1_NAMADA got swapped for $BALANCE_DIFF $DENOM2_NAMADA!"
          gum log --structured --level info "Give it a minute or two and make sure to perform a shielded sync before checking your balance."

          CHOICE_1="Perform a shielded-sync and check balance(s) (warning: do not do this if you scripted shielded-sync to auto-run!)"
          CHOICE_2="Check balance(s)"
          CHOICE_BACK="Back to main menu"

          MENU_CHOICE=$(gum choose  --header "What's next?" "$CHOICE_1" "$CHOICE_2" "$CHOICE_BACK")

          # Make DENOM1 uosmo and DENOM2 naan/nam instead if we are doing the reverted swap
          if [ "$MENU_CHOICE" = "$CHOICE_1" ]; then
            shielded_sync
            bash layout/balance.sh
          elif [ "$MENU_CHOICE" = "$CHOICE_2" ]; then
            bash layout/balance.sh
          elif [ "$MENU_CHOICE" = "$CHOICE_BACK" ]; then
            bash layout/main.sh
          fi
        fi
      fi
    else
      echo_fail "Swap got canceled."
      bash layout/main.sh
    fi
  else
    echo_fail "The amount you provided to swap is too low, the pool would return 0 tokens. Make sure to swap a sufficient amount."
    bash layout/main.sh
  fi
else
  echo_fail "You can't continue doing a shielded swap for not having enough balance!"
  bash layout/main.sh
fi