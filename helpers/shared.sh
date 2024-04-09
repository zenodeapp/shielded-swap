#!/bin/bash

# Check if a command is installed and readily available for use
command_available() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "YES"
  else
    echo "NO"
  fi
}

# Get osmosis balance using osmosisd
get_osmosis_balance() {
  DENOM=$1

  if [ -z $DENOM ] || [ -z $OSMO_ADDRESS ] || [ -z $OSMO_CHAIN_ID ] || [ -z $OSMO_RPC ]; then
    echo ""
  else
    echo "$(osmosisd query bank balances $OSMO_ADDRESS --chain-id $OSMO_CHAIN_ID --node $OSMO_RPC --output json --denom $DENOM)" | jq -r '.amount'
  fi
}

# Get namada balance using namada client (namadac)
get_namada_balance() {
  DENOM=$1
  DENOM_REGEX=$(echo "$DENOM" | sed 's/\//\\\//g') # needed to prevent awk from failing over the forward slashes
  
  if [ -z $DENOM ] || [ -z $NAM_TRANSPARENT ] || [ -z $NAM_CHAIN_ID ] || [ -z $NAM_RPC ]; then
    echo ""
  else
    echo "$(namada client balance --chain-id $NAM_CHAIN_ID --owner $NAM_TRANSPARENT --node $NAM_RPC 2>/dev/null | awk "/^$DENOM_REGEX/{print; exit}")" | awk -F ': ' '{print $2}'
  fi
}

# Get namada shielded balance using namada client (namadac)
get_namada_shielded_balance() {
  DENOM=$1
  DENOM_REGEX=$(echo "$DENOM" | sed 's/\//\\\//g') # needed to prevent awk from failing over the forward slashes

  # This might need some shielded-sync logic

  if [ -z $DENOM ] || [ -z $NAM_VIEWING_KEY ] || [ -z $NAM_CHAIN_ID ] || [ -z $NAM_RPC ]; then
    echo ""
  else
    echo "$(namada client balance --chain-id $NAM_CHAIN_ID --owner $NAM_VIEWING_KEY --node $NAM_RPC 2>/dev/null | awk "/^$DENOM_REGEX/{print; exit}")" | awk -F ': ' '{print $2}'
  fi
}

shorten_address() {
  ADDRESS="$1"
  FIRST_LENGTH="${2:-6}"
  LAST_LENGTH="${3:-6}"
  MAX_LENGTH="${4:-45}"

  if (( ${#ADDRESS} > MAX_LENGTH )); then
    FIRST_PART="${ADDRESS:0:FIRST_LENGTH}"
    LAST_PART="${ADDRESS: -LAST_LENGTH}"
    echo "$FIRST_PART...$LAST_PART"
  else
    echo "$ADDRESS"
  fi
}