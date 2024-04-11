#!/bin/bash

# Source shared functions
source helpers/shared.sh

# Source input functions
source helpers/input.sh

# Functions
print_balance_block_header() {
  HEADING="$1"
  ADDRESS=${2:-"No address has been configured."}
  COLOR=$3

  gum style --padding "1 2" --margin "0" --border double --border-foreground $COLOR --foreground $COLOR "$HEADING" \
    "$ADDRESS"
}

print_balance_block_value() {
  TITLE="$1"
  BALANCE=${2:-"No balance found."}
  COLOR="$3"

  gum style --foreground $COLOR "> $TITLE: $BALANCE"
}

# Blocks
print_balance_block_header "OSMOSIS" "$OSMO_ADDRESS" 810
print_balance_block_value "uosmo" "$(get_osmosis_balance uosmo)" 810
print_balance_block_value "$NAM_DENOM" "$(get_osmosis_balance $NAM_IBC)" 810
echo ""
print_balance_block_header "NAMADA (TRANSPARENT)" "$NAM_TRANSPARENT" 1500
print_balance_block_value "$NAM_DENOM" "$(get_namada_transparent_balance "$NAM_DENOM")" 1500
print_balance_block_value "uosmo${NAM_CHANNEL:+ ($NAM_CHANNEL)}" "$(get_namada_transparent_balance "$NAM_UOSMO_DENOM")" 1500
echo ""
print_balance_block_header "NAMADA (SHIELDED)" "$(shorten_address "$NAM_VIEWING_KEY" 21 21)" 795
print_balance_block_value "$NAM_DENOM" "$(get_namada_shielded_balance "$NAM_DENOM")" 795
print_balance_block_value "uosmo${NAM_CHANNEL:+ ($NAM_CHANNEL)}" "$(get_namada_shielded_balance "$NAM_UOSMO_DENOM")" 795
echo ""

# Give warning for usage of shielded sync
gum log --structured --level warn "Do not perform a shielded-sync if you scripted this to auto-run periodically!"
echo ""

# Menu
CHOICE_PERFORM_SS="Perform shielded sync and reload balances"
CHOICE_BACK="Back"

MENU_CHOICE=$(gum choose  --header "What would you like to do?" "$CHOICE_PERFORM_SS" "$CHOICE_BACK")

if [ "$MENU_CHOICE" = "$CHOICE_PERFORM_SS" ]; then
  shielded_sync
  bash layout/balance.sh
else
  bash layout/main.sh
fi