#!/bin/bash
  
get_osmosis_balance() {
  DENOM=$1

  echo "$(osmosisd query bank balances $OSMO_ADDRESS --node $OSMO_RPC --output json --denom $DENOM)" | jq -r '.amount'
}

get_namada_balance() {
  DENOM=$1
  SHIELDED=$2

  if [ "$SHIELDED" = "true" ]; then
    ADDRESS=$NAM_VIEWING_KEY
  else
    ADDRESS=$NAM_TRANSPARENT
  fi

  escaped_denom=$(echo "$DENOM" | sed 's/\//\\\//g')
  echo "$(namada client balance --owner $ADDRESS --node $NAM_RPC 2>/dev/null | awk "/^$escaped_denom/{print; exit}")" | awk -F ': ' '{print $2}'
}

print_balance_block_header() {
  HEADING="$1"
  ADDRESS="$2"
  COLOR=$3

  gum style --padding "1 2" --margin "0" --border double --border-foreground $COLOR --foreground $COLOR "$HEADING" \
    "$ADDRESS"
}

print_balance_block_value() {
  VALUE="$1"
  COLOR="$2"

  gum style --foreground $COLOR "$VALUE"
}

print_balance_block_header "OSMOSIS" "$OSMO_ADDRESS" 810
print_balance_block_value "> naan: $(get_osmosis_balance $NAM_IBC)" 810
print_balance_block_value "> uosmo: $(get_osmosis_balance uosmo)" 810
echo ""

print_balance_block_header "NAMADA (TRANSPARENT)" "$NAM_TRANSPARENT" 1500
print_balance_block_value "> naan: $(get_namada_balance "naan" "false")" 1500
print_balance_block_value "> uosmo ($NAM_CHANNEL): $(get_namada_balance "$NAM_UOSMO_DENOM" "false")" 1500
echo ""

print_balance_block_header "NAMADA (SHIELDED)" "$NAM_SHIELDED" 795
print_balance_block_value "> naan: $(get_namada_balance "naan" "true")" 795
print_balance_block_value "> uosmo ($NAM_CHANNEL): $(get_namada_balance "$NAM_UOSMO_DENOM" "true")" 795
echo ""

# Menu
MENU_CHOICE=$(gum choose  --header "What would you like to do?" "Go back")
if [ "$MENU_CHOICE" = "Go back" ]; then
  bash menu/first_screen.sh
fi