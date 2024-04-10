#!/bin/bash

# Source shared functions
source helpers/shared.sh

# Source input functions
source helpers/input.sh

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

print_balance_block_header "OSMOSIS" "$OSMO_ADDRESS" 810
print_balance_block_value "uosmo" "$(get_osmosis_balance uosmo)" 810
print_balance_block_value "naan" "$(get_osmosis_balance $NAM_IBC)" 810
echo ""
print_balance_block_header "NAMADA (TRANSPARENT)" "$NAM_TRANSPARENT" 1500
print_balance_block_value "naan" "$(get_namada_balance "$NAM_DENOM")" 1500
print_balance_block_value "uosmo${NAM_CHANNEL:+ ($NAM_CHANNEL)}" "$(get_namada_balance "$NAM_UOSMO_DENOM")" 1500
echo ""
print_balance_block_header "NAMADA (SHIELDED)" "$(shorten_address $NAM_VIEWING_KEY 21 21)" 795
print_balance_block_value "naan" "$(get_namada_shielded_balance "$NAM_DENOM")" 795
print_balance_block_value "uosmo${NAM_CHANNEL:+ ($NAM_CHANNEL)}" "$(get_namada_shielded_balance "$NAM_UOSMO_DENOM")" 795
echo ""

# Menu
CHOICE_BACK="Go back"

MENU_CHOICE=$(gum choose  --header "What would you like to do?" "$CHOICE_BACK")

if [ "$MENU_CHOICE" = "$CHOICE_BACK" ]; then
  bash layout/main.sh
fi