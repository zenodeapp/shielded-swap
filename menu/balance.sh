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

gum style --padding "1 2" --margin "0" --border double --border-foreground 810 --foreground 810 "OSMOSIS" \
  "$OSMO_ADDRESS"
gum style --foreground 810 "> uosmo: $(get_osmosis_balance uosmo)"
gum style --foreground 810 "> naan: $(get_osmosis_balance $NAM_IBC)"

echo ""

gum style --padding "1 2" --border double --border-foreground 1500 --foreground 1500 "NAMADA (TRANSPARENT)" \
 "$NAM_TRANSPARENT"
gum style --foreground 1500 "> naan: $(get_namada_balance "naan" "false")"
gum style --foreground 1500 "> uosmo ($NAM_CHANNEL): $(get_namada_balance "transfer/$NAM_CHANNEL/uosmo" "false")"

echo ""

gum style --padding "1 2" --border double --border-foreground 795 --foreground 795 "NAMADA (SHIELDED)" \
  "$NAM_SHIELDED"
gum style --foreground 795 "> naan: $(get_namada_balance "naan" "true")"
gum style --foreground 795 "> uosmo ($NAM_CHANNEL): $(get_namada_balance "transfer/$NAM_CHANNEL/uosmo" "true")"

echo ""

# Menu
MENU_CHOICE=$(gum choose  --header "What would you like to do?" "Back")
if [ "$MENU_CHOICE" = "Back" ]; then
  bash menu/first_screen.sh
fi