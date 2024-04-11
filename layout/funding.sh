#!/bin/bash

# Source shared functions
source helpers/shared.sh

# Source input functions
source helpers/input.sh

# Menu
CHOICE_OSMOSIS="1. Send nam from a transparent account to your osmosis address"
CHOICE_NAMADA="2. Send uosmo from an osmosis address to your transparent account"
CHOICE_BACK="Back"

MENU_CHOICE=$(gum choose  --header "What would you like to do?" "$CHOICE_OSMOSIS" "$CHOICE_NAMADA" "$CHOICE_BACK")

if [ "$MENU_CHOICE" = "$CHOICE_OSMOSIS" ]; then
  # fund osmosis address
  AMOUNT=$(repeat_input_number "How much $NAM_DENOM from $NAM_TRANSPARENT would you like to send to $(shorten_address "$OSMO_ADDRESS") [balance: $(get_namada_transparent_balance "$NAM_DENOM") "$NAM_DENOM"]?" "false")
  gum spin --show-output --title "Sending $AMOUNT $NAM_DENOM from $(shorten_address "$NAM_TRANSPARENT") to $(shorten_address "$OSMO_ADDRESS")..." sleep 1
  transfer_transparent_ibc_namada "$OSMO_ADDRESS" "$NAM_DENOM" "$AMOUNT"
  echo ""
  # TODO: Needs validation
  echo_success "Send $AMOUNT $NAM_DENOM over IBC to $OSMO_ADDRESS. It may take a moment to get relayed to your address."
  bash layout/funding.sh
elif [ "$MENU_CHOICE" = "$CHOICE_NAMADA" ]; then
  # fund namada address
  AMOUNT=$(repeat_input_number "How much uosmo (from '$OSMO_KEY') would you like to send to $(shorten_address "$NAM_TRANSPARENT") [balance: $(get_osmosis_balance "uosmo") "uosmo"]?" "false")
  gum spin --spinner.foreground="800" --show-output --title "Sending $AMOUNT uosmo from $(shorten_address "$OSMO_ADDRESS") to $(shorten_address "$NAM_TRANSPARENT")..." sleep 1
  transfer_ibc_osmosis "$NAM_TRANSPARENT" "uosmo" "$AMOUNT" ""
  echo ""
  # TODO: Needs validation
  echo_success "Send $AMOUNT uosmo over IBC to $NAM_TRANSPARENT. It may take a moment to get relayed to your address."
  bash layout/funding.sh
else
  bash layout/main.sh
fi