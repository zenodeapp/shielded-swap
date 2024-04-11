#!/bin/bash

# TODO: this could be refactored; abstracting same logic into functions.

# Source input functions
source helpers/input.sh

# Source set functions (also validates configurations)
source config/set.sh

CHOICE_OSMOSIS_KEY="1. Create a new osmosis key"
CHOICE_TRANSPARENT_KEY="2. Create a new (transparent) namada key"
CHOICE_SHIELDED_KEYS="3. Create new (shielded) namada keys (viewing key and payment address)"
CHOICE_BACK="Back"

MENU_CHOICE=$(gum choose  --header "What would you like to do?" "$CHOICE_OSMOSIS_KEY" "$CHOICE_TRANSPARENT_KEY" "$CHOICE_SHIELDED_KEYS" "$CHOICE_BACK")

if [ "$MENU_CHOICE" = "$CHOICE_OSMOSIS_KEY" ]; then
  CONFIG_KEY="osmoKey"
  DEFAULT_ALIAS="osmokey"
  ALIAS=$(gum input --placeholder "What alias would you like to use for this new key? [default: $DEFAULT_ALIAS]")
  
  if [ -z "$ALIAS" ]; then
    ALIAS="$DEFAULT_ALIAS"
  fi

  osmosisd keys add "$ALIAS"
  modify_config_key "osmoKey" "$ALIAS"
  
  # TODO: Resets for now; find a way to extract the address and set this as well or remove that field from config in its entirety.
  modify_config_key "osmoAddress" ""

  echo ""
  echo_success "The osmoKey value was changed to $ALIAS!"
  gum log --structured --level warn "Make sure to also change the osmoAddress field in the config.json file to the address above!"
elif [ "$MENU_CHOICE" = "$CHOICE_TRANSPARENT_KEY" ]; then
  CONFIG_KEY="namImplicitKey"
  DEFAULT_ALIAS="transparentkey"
  ALIAS=$(gum input --placeholder "What alias would you like to use for this new transparent key? [default: $DEFAULT_ALIAS]")

  if [ -z "$ALIAS" ]; then
    ALIAS="$DEFAULT_ALIAS"
  fi

  namada wallet gen --alias "$ALIAS" --chain-id "$NAM_CHAIN_ID"
  modify_config_key "$CONFIG_KEY" "$ALIAS"

  echo ""
  echo_success "The $CONFIG_KEY value was changed to $ALIAS!"
  gum log --structured --level warn "Make sure to change the namTransparent field in the config.json file to the address above!"
elif [ "$MENU_CHOICE" = "$CHOICE_SHIELDED_KEYS" ]; then
  # Viewing key creation
  CONFIG_KEY="namViewingKey"
  DEFAULT_ALIAS="viewingkey"
  ALIAS=$(gum input --placeholder "What alias would you like to use for the viewing key? [default: viewingkey]")

  if [ -z "$ALIAS" ]; then
    ALIAS="$DEFAULT_ALIAS"
  fi

  namada wallet gen --alias "$ALIAS" --chain-id "$NAM_CHAIN_ID" --shielded
  modify_config_key "$CONFIG_KEY" "$ALIAS"

  echo ""
  echo_success "The $CONFIG_KEY value was changed to $ALIAS!"

  # Payment key creation
  VIEWING_KEY="$ALIAS"
  CONFIG_KEY="namPayment"
  DEFAULT_ALIAS="$VIEWING_KEY-pay"
  ALIAS=$(gum input --placeholder "What alias would you like to use for the payment key? [default: $DEFAULT_ALIAS]")

  if [ -z "$ALIAS" ]; then
    ALIAS="$DEFAULT_ALIAS"
  fi

  namada wallet gen-payment-addr --alias "$ALIAS" --chain-id "$NAM_CHAIN_ID" --key "$VIEWING_KEY"
  
  # TODO: Resets for now; find a way to extract the address and set this as well.
  modify_config_key "$CONFIG_KEY" ""
  # modify_config_key "$CONFIG_KEY" "$ALIAS"

  echo ""
  gum log --structured --level warn "Make sure to change the $CONFIG_KEY field in the config.json file to the address above!"
fi

bash layout/config.sh
