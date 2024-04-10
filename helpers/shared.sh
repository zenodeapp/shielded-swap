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

# Get osmosis balances using osmosisd
get_osmosis_balances() {
  if [ -z $OSMO_ADDRESS ] || [ -z $OSMO_CHAIN_ID ] || [ -z $OSMO_RPC ]; then
    echo ""
  else
    echo "$(osmosisd query bank balances $OSMO_ADDRESS --chain-id $OSMO_CHAIN_ID --node $OSMO_RPC --output json)"
  fi
}

get_gamm_pool_denoms() {
  local result
  result=$(get_osmosis_balances)

  local -a denoms=()
  # Use jq to filter denoms that start with 'gamm/pool'
  while IFS= read -r line; do
    denoms+=("$line")
  done < <(echo "$result" | jq -r '.balances[] | select(.denom | startswith("gamm/pool")) | .denom')

  echo "${denoms[@]}"
}

create_osmosis_pool_json() {
  DENOM1=$1
  DENOM2=$2
  DENOM1_WEIGHT=$3
  DENOM2_WEIGHT=$4
  DENOM1_AMOUNT=$5
  DENOM2_AMOUNT=$6

  echo "{
    \"weights\": \"$DENOM1_WEIGHT$DENOM1,$DENOM2_WEIGHT$DENOM2\",
    \"initial-deposit\": \"$DENOM1_AMOUNT$DENOM1,$DENOM2_AMOUNT$DENOM2\",
    \"swap-fee\": \"0.01\",
    \"exit-fee\": \"0.00\",
    \"future-governor\": \"168h\"
  }" > .tmp/pool.json
}

create_osmosis_pool() {
  POOL_FILE=$1
  osmosisd tx gamm create-pool --chain-id $OSMO_CHAIN_ID --pool-file $POOL_FILE --node $OSMO_RPC --from $OSMO_KEY --log_format json -y --fees 1500uosmo --gas 500000
}

# Get osmosis pool info as json
get_osmosis_pool_json() {
  POOL_ID=$1

  POOL_INFO="$(osmosisd query gamm pool $POOL_ID --chain-id $OSMO_CHAIN_ID --node $OSMO_RPC --output json 2>/dev/null)"
  
  echo $POOL_INFO
}

# Use this function in combination with get_osmosis_pool_json.
# This returns the value for a specific key.
get_osmosis_pool_info() {
  POOL_INFO=$1
  KEY=$2

  if [ -z $POOL_INFO ]; then
    echo ""
  elif [ $KEY = "id" ]; then
    echo "$POOL_INFO" | jq -r '.pool.id'
  elif [ $KEY = "address" ]; then
    echo "$POOL_INFO" | jq -r '.pool.address'
  elif [ $KEY = "denom0" ]; then
    echo "$POOL_INFO" | jq -r '.pool.total_shares.denom'
  elif [ $KEY = "swap_fee" ]; then
    echo "$POOL_INFO" | jq -r '.pool.pool_params.swap_fee'
  elif [ $KEY = "exit_fee" ]; then
    echo "$POOL_INFO" | jq -r '.pool.pool_params.exit_fee'
  elif [ $KEY = "denom1" ]; then
    echo "$POOL_INFO" | jq -r '.pool.pool_assets[0].token.denom'
  elif [ $KEY = "amount1" ]; then
    echo "$POOL_INFO" | jq -r '.pool.pool_assets[0].token.amount'
  elif [ $KEY = "denom2" ]; then
    echo "$POOL_INFO" | jq -r '.pool.pool_assets[1].token.denom'
  elif [ $KEY = "amount2" ]; then
    echo "$POOL_INFO" | jq -r '.pool.pool_assets[1].token.amount'
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

print_array() {
  local -n ARRAY=$1

  echo "$ARRAY"
  
  for ITEM in "${ARRAY[@]}"; do
    echo "$ITEM"
  done
}

print_key_pairs() {
  local -n KEYS=$1
  local -n VALUES=$2
  
  for ((i=0; i<${#KEYS[@]}; i++)); do
    echo "${KEYS[$i]} - ${VALUES[$i]}"
  done
}