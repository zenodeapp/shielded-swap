#!/bin/bash

# TODO: this could be refactored; abstracting same logic into functions.

# Source shared functions
source helpers/shared.sh

# Source input functions
source helpers/input.sh

# Check if all values are provided
source config/validate_values.sh

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
CHOICE_1="1. Perform a shielded swap from $DENOM1_NAMADA => $DENOM2_OSMOSIS ($NAM_CHANNEL)"
CHOICE_2="2. Perform a shielded swap from $DENOM2_OSMOSIS ($NAM_CHANNEL) => $DENOM1_NAMADA"
CHOICE_3="3. Shield an asset"
CHOICE_4="4. Unshield an asset"
CHOICE_BACK="Back"

MENU_CHOICE=$(gum choose  --header "What type of shielded action would you like to perform?" "$CHOICE_1" "$CHOICE_2" "$CHOICE_3" "$CHOICE_4" "$CHOICE_BACK")

if [ "$MENU_CHOICE" = "$CHOICE_1" ] || [ "$MENU_CHOICE" = "$CHOICE_2" ]; then
  # Here we do shielded-swap actions

  # Make DENOM1 uosmo and DENOM2 naan/nam instead if we are doing the reverted swap
  if [ "$MENU_CHOICE" = "$CHOICE_1" ]; then
    SENDING_NAM=true
  elif [ "$MENU_CHOICE" = "$CHOICE_2" ]; then
    SENDING_NAM=false
    DENOM1_NAMADA="$NAM_UOSMO_DENOM"
    DENOM1_OSMOSIS="uosmo"
    DENOM2_NAMADA="$NAM_DENOM"
    DENOM2_OSMOSIS="$NAM_IBC"
  fi

  if [ "$SHIELDED_BROKEN" = 'true' ]; then
    CONFIRM_ACTION=$(gum confirm "Swapping $DENOM1_NAMADA to $DENOM2_NAMADA while shieldedBroken is true will start the swap action using the transparent address '$NAM_TRANSPARENT', but sends the swapped token back to '$NAM_VIEWING_KEY'. Do you want to continue?" && echo "true" || echo "false")
  else
    CONFIRM_ACTION=$(gum confirm "This will swap $DENOM1_NAMADA to $DENOM2_NAMADA using payment address '$(shorten_address "$OSMO_KEY")' and viewing key '$NAM_VIEWING_KEY'. Do you want to continue?" && echo "true" || echo "false")
  fi

  if [ "$CONFIRM_ACTION" = "true" ]; then
    # Perform a shielded sync 
    if ! [ "$SHIELDED_BROKEN" = 'true' ]; then
      CONFIRM_SS=$(gum confirm "Do you want to perform a shielded sync before swapping?" && echo "true" || echo "false")

      if [ "$CONFIRM_SS" = "true" ]; then
        shielded_sync
      fi
    fi

    ### CHECK BALANCES ###
    # Before we can swap we need to make sure that we have enough uosmo on osmosis and enough naan on namada
    echo ""
    header_block "SHIELDED SWAP" 400

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
    gum spin --spinner.foreground="800" --show-output --title "Checking balance on $(shorten_address "$OSMO_ADDRESS")..." sleep 2
    MIN_UOSMO=1000000
    OSMOSIS_UOSMO_BALANCE=$(get_osmosis_balance "uosmo")
    OSMOSIS_UOSMO_BALANCE_VALID=$(check_balance "uosmo" "$OSMOSIS_UOSMO_BALANCE" "$MIN_UOSMO")

    # Check naan/nam balance on namada
    gum spin --show-output --title "Checking balance on $(shorten_address "$NAM_ADDRESS" 19 19)..." sleep 2
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
      gum spin --show-output --title "Checking balance of "$DENOM1_NAMADA" on $(shorten_address "$NAM_ADDRESS" 19 19)..." sleep 2
      BALANCE_AVAILABLE=$(get_namada_balance "$DENOM1_NAMADA")
      BALANCE_AVAILABLE_VALID=$(check_balance "$DENOM1_NAMADA" "$BALANCE_AVAILABLE" "$MIN_DENOM2")
    fi

    # Check if all balances are valid
    if [ "$OSMOSIS_UOSMO_BALANCE_VALID" = "true" ] && [ "$NAMADA_NAM_BALANCE_VALID" = "true" ] && [ "$BALANCE_AVAILABLE_VALID" = "true" ]; then
      echo_success "Enough balance found on both addresses!"
      ### SWAP PREVIEW ###
      # Before we can start the process we'll preview the swap
      echo ""
      header_block "SWAP PREVIEW" 400

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
        BLOCK1=$(gum style --padding "1 2" --margin "0" --border normal --border-foreground 300 --foreground 300 " SEND" \ "$AMOUNT_TO_TRANSFER" \ "$DENOM1_NAMADA") 
        BLOCK2=$(gum style --padding "1 2" --margin "0" --border normal --border-foreground 800 --foreground 800 " RECEIVE" \ "$ESTIMATE_AMOUNT_MIN ~ $ESTIMATE_AMOUNT" \ "$DENOM2_NAMADA") 
        gum join "$BLOCK1" "$BLOCK2"

        CONFIRM_SWAP=$(gum confirm "You will receive a minimum of $ESTIMATE_AMOUNT_MIN $DENOM2_NAMADA (slippage: $SLIPPAGE%), do you want to continue?" && echo "true" || echo "false")

        if [ "$CONFIRM_SWAP" = "true" ]; then
          ### FROM NAMADA => OSMOSIS ###
          echo ""
          header_block "NAMADA => OSMOSIS"
          
          # Check balance on osmosis side
          gum spin --spinner.foreground="800" --show-output --title "Checking balance for $DENOM1_OSMOSIS on $(shorten_address $OSMO_ADDRESS)..." sleep 2
          BALANCE_TARGET=$(get_osmosis_balance "$DENOM1_OSMOSIS")
          BALANCE_TARGET_COUNTER=$(get_osmosis_balance "$DENOM2_OSMOSIS")
          gum log --structured --level info "Found $BALANCE_TARGET $DENOM1_OSMOSIS."
          echo ""

          # Send the tokens from namada to osmosis
          gum spin --show-output --title "Transferring $AMOUNT_TO_TRANSFER $DENOM1_NAMADA from $(shorten_address $NAM_ADDRESS 19 19) over IBC to $(shorten_address $OSMO_ADDRESS)..." sleep 2
          transfer_ibc_namada "$OSMO_ADDRESS" "$DENOM1_NAMADA" "$AMOUNT_TO_TRANSFER"

          # Check if token got transferred
          BALANCE_RECEIVER=$(loop_check_balance_osmosis "$DENOM1_OSMOSIS" "$BALANCE_TARGET" "$AMOUNT_TO_TRANSFER")

          if [ -z "$BALANCE_RECEIVER" ]; then
            echo_fail "Transaction timed out...no $DENOM1_OSMOSIS was received on $(shorten_address $OSMO_ADDRESS 6 6 38)."
            bash layout/main.sh
          else
            echo ""
            echo_success "$AMOUNT_TO_TRANSFER $DENOM1_OSMOSIS received. Balance on $(shorten_address $OSMO_ADDRESS 6 6 38) is now $BALANCE_RECEIVER $DENOM1_OSMOSIS!"
            
            ### SWAP ON OSMOSIS CHAIN ###
            echo ""
            header_block "SWAP ON OSMOSIS" 800

            gum spin --spinner.foreground="800" --show-output --title "Swapping $AMOUNT_TO_TRANSFER $DENOM1_OSMOSIS for $ESTIMATE_AMOUNT_MIN ~ $ESTIMATE_AMOUNT $DENOM2_OSMOSIS..." sleep 2
            swap_exact_amount_in "$DENOM1_OSMOSIS" "$AMOUNT_TO_TRANSFER" "$ESTIMATE_AMOUNT_MIN"

            # Check that you got the tokens and see how many
            BALANCE_RECEIVER=$(loop_check_balance_osmosis "$DENOM2_OSMOSIS" "$BALANCE_TARGET_COUNTER" "$AMOUNT_TO_TRANSFER")

            if [ -z "$BALANCE_RECEIVER" ]; then
              echo_fail "Transaction timed out...no $DENOM1_OSMOSIS got swapped on $(shorten_address $OSMO_ADDRESS 6 6 38)."
              bash layout/main.sh
            else
              # Calculate the difference in balance before and after the swap for the token we're preparing to send back to Namada
              BALANCE_DIFF=$(bc <<< "$BALANCE_RECEIVER - $BALANCE_TARGET_COUNTER")

              # Make sure not to give more than we expected at max (Upper bound)
              # Imagine a scenario where someone sends a lot of tokens to this address at the same time.
              # This would cause the shielded swap to send back all those tokens as well if we only took BALANCE_DIFF into account.
              if [ "$(echo "$BALANCE_DIFF > $ESTIMATE_AMOUNT" | bc)" -eq 1 ]; then
                BALANCE_DIFF=$ESTIMATE_AMOUNT
              fi

              echo ""
              echo_success "$AMOUNT_TO_TRANSFER $DENOM1_OSMOSIS got swapped for $BALANCE_DIFF $DENOM2_OSMOSIS on osmosis!"
              
                ### SEND BACK TO NAMADA ###
              echo ""
              header_block "SEND BACK TO NAMADA" 800
              gum spin --show-output --title "Preparing IBC memo for transfer back..." sleep 2
              IBC_MEMO=$(gen_ibc_memo "$NAM_PAYMENT" "$DENOM2_OSMOSIS" "$BALANCE_DIFF")
              gum log --structured --level info "Generated: $IBC_MEMO."

              echo ""
              gum spin --spinner.foreground="800" --show-output --title "Sending $BALANCE_DIFF $DENOM2_OSMOSIS to $(shorten_address $NAM_PAYMENT)..." sleep 2
              transfer_ibc_osmosis "$NAM_PAYMENT" "$DENOM2_OSMOSIS" "$BALANCE_DIFF" "$IBC_MEMO"

              # End of swap
              echo ""
              echo_success "$AMOUNT_TO_TRANSFER $DENOM1_NAMADA got swapped for $BALANCE_DIFF $DENOM2_NAMADA!"
              
              echo ""
              # Give info about next steps
              gum log --structured --level info "Give it a minute or two and make sure to perform a shielded sync before checking your balance."
              
              # Give warning for usage of shielded sync
              gum log --structured --level warn "Do not perform a shielded-sync if you scripted this to auto-run periodically!"
              echo ""
              
              CHOICE_1="1. Check balance(s)"
              CHOICE_2="2. Perform a shielded-sync and check balance(s)"
              CHOICE_BACK="Back to main menu"

              MENU_CHOICE=$(gum choose  --header "What's next?" "$CHOICE_1" "$CHOICE_2" "$CHOICE_BACK")

              if [ "$MENU_CHOICE" = "$CHOICE_1" ]; then
                bash layout/balance.sh
              elif [ "$MENU_CHOICE" = "$CHOICE_2" ]; then
                shielded_sync
                bash layout/balance.sh
              else
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
  else
    bash layout/main.sh
  fi

elif [ "$MENU_CHOICE" = "$CHOICE_3" ] || [ "$MENU_CHOICE" = "$CHOICE_4" ]; then
  
  # Indicator whether we're shielding or unshielding
  if [ "$MENU_CHOICE" = "$CHOICE_3" ]; then
    SHIELD_ACTION=true
  else
    SHIELD_ACTION=false
  fi

  if $SHIELD_ACTION; then
    SHIELD_WORD="shield"
    CONFIRM_ACTION=$(gum confirm "This will shield assets (from transparent address '$NAM_TRANSPARENT' to payment address '$(shorten_address "$NAM_PAYMENT")'). Do you want to continue?" && echo "true" || echo "false")
  else
    SHIELD_WORD="unshield"
    CONFIRM_ACTION=$(gum confirm "This will unshield assets (from viewing key '$NAM_VIEWING_KEY' to transparent address '$NAM_TRANSPARENT'). Do you want to continue?" && echo "true" || echo "false")
  fi

  if [ "$CONFIRM_ACTION" = "true" ]; then
    echo ""
    header_block "${SHIELD_WORD^^} AN ASSET"

    if ! $SHIELD_ACTION && [ "$SHIELDED_BROKEN" = "true" ]; then
      gum log --structured --level warn "Unshielding only works if the chain is not broken! Currently shieldedBroken is set to $SHIELDED_BROKEN; set it to false to remove this warning." 
    fi

    gum log --structured --level warn "Do not perform a shielded-sync if you scripted this to auto-run periodically!" 
    CONFIRM_SS=$(gum confirm "Do you want to perform a shielded sync before "$SHIELD_WORD"ing (sometimes optional)?" && echo "true" || echo "false")

    if [ "$CONFIRM_SS" = "true" ]; then
      shielded_sync
    fi

    TOKEN=$(repeat_input "Which token would you like to $SHIELD_WORD? (e.g. $NAM_DENOM, $NAM_UOSMO_DENOM etc.)")

    if $SHIELD_ACTION; then
      AMOUNT=$(repeat_input_number "How much of $TOKEN would you like to send to $(shorten_address "$NAM_PAYMENT")?" "false")
      gum spin --show-output --title "Sending $AMOUNT $TOKEN from $NAM_TRANSPARENT to $(shorten_address "$NAM_PAYMENT")..." sleep 1
      namada client transfer --token $TOKEN --amount $AMOUNT --source $NAM_TRANSPARENT --target $NAM_PAYMENT --chain-id $NAM_CHAIN_ID --node $NAM_RPC
      echo ""
      # TODO: Needs validation
      echo_success "Attemped to shield $AMOUNT $TOKEN (see '$NAM_VIEWING_KEY' address)."
    else
      AMOUNT=$(repeat_input_number "How much of $TOKEN would you like to send to '$NAM_TRANSPARENT'?" "false")
      gum spin --show-output --title "Sending $AMOUNT $TOKEN from $(shorten_address "$NAM_VIEWING_KEY") to $(shorten_address "$NAM_TRANSPARENT")..." sleep 1
      namada client transfer --token $TOKEN --amount $AMOUNT --source $NAM_VIEWING_KEY --target $NAM_TRANSPARENT --chain-id $NAM_CHAIN_ID --node $NAM_RPC --signing-keys $NAM_TRANSPARENT
      echo ""
      # TODO: Needs validation
      echo_success "Attemped to unshield $AMOUNT $TOKEN (see '$NAM_TRANSPARENT' address)."
    fi

    # Give info about next steps
    if $SHIELD_ACTION; then
      echo ""
      gum log --structured --level info "Make sure to perform a shielded sync before checking your balance."
      # Give warning for usage of shielded sync
      gum log --structured --level warn "Do not perform a shielded-sync if you scripted this to auto-run periodically!"
      echo ""
    fi

    CHOICE_1="1. Check balance(s)"
    CHOICE_2="2. Perform a shielded-sync and check balance(s)"
    CHOICE_BACK="Back to main menu"

    if $SHIELD_ACTION; then
      MENU_CHOICE=$(gum choose  --header "What's next?" "$CHOICE_1" "$CHOICE_2" "$CHOICE_BACK")
    else
      MENU_CHOICE=$(gum choose  --header "What's next?" "$CHOICE_1" "$CHOICE_BACK")
    fi

    if [ "$MENU_CHOICE" = "$CHOICE_1" ]; then
      bash layout/balance.sh
    elif [ "$MENU_CHOICE" = "$CHOICE_2" ]; then
      shielded_sync
      bash layout/balance.sh
    else
      bash layout/main.sh
    fi
  else
    bash layout/main.sh
  fi
else
  bash layout/main.sh
fi