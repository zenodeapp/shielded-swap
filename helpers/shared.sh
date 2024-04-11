#!/bin/bash

# Source input functions
source helpers/input.sh

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
    echo "0"
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

# This checks every 2 seconds whether the balance for a specified denom changed, it times out after 2 minutes.
loop_check_balance_osmosis() {
  DENOM="$1"
  START_AMOUNT="$2"
  AMOUNT_TO_ADD="$3"
  START_TIME=$(date +%s)
  TIMEOUT=120 # Check for max of 2 minutes
  TIMEOUT_REACHED=true

  while [ "$(date +%s)" -lt "$(($START_TIME + $TIMEOUT))" ]; do
    BALANCE=$(get_osmosis_balance "$DENOM")
    gum spin --title "Checking balance for $DENOM on $OSMO_ADDRESS..." -- sleep 2

    if (( $(bc <<< "$BALANCE > $START_AMOUNT") )); then
      echo "$BALANCE"
      TIMEOUT_REACHED=false
      break
    fi
  done

  if $TIMEOUT_REACHED; then
    echo ""
  fi
}

# Get all the gamm/pool assets owned by the configured osmoAddress
get_gamm_pool_denoms() {
  RESULT=$(get_osmosis_balances)

  local -a denoms=()

  while IFS= read -r line; do
    denoms+=("$line")
  done < <(echo "$RESULT" | jq -r '.balances[] | select(.denom | startswith("gamm/pool")) | .denom')

  echo "${denoms[@]}"
}

# Create the json file for the creation of an osmosis pool
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

# Create an osmosis pool
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

get_counter_token_in_pool() {
  TOKEN_IN="$1"

  # Get pool id data
  POOL_ID_DATA=$(get_osmosis_pool_json $OSMO_POOL_ID)

  DENOM1=$(get_osmosis_pool_info "$POOL_ID_DATA" "denom1")
  DENOM2=$(get_osmosis_pool_info "$POOL_ID_DATA" "denom2")

  if [ "$DENOM1" = "$TOKEN_IN" ]; then
    echo "$DENOM2"
  elif [ "$DENOM2" = "$TOKEN_IN" ]; then
    echo "$DENOM1"
  else
    echo ""
  fi
}

# Calculates how many tokens you will receive if you do this transaction.
estimate_swap_amount() {
  TOKEN_IN="$1"
  TOKEN_AMOUNT_IN="$2"

  # Get token out based on token in using the pool id
  TOKEN_OUT=$(get_counter_token_in_pool "$TOKEN_IN")

  if [ -z "$TOKEN_OUT" ]; then
    echo "0"
  else
    TOKEN_AMOUNT_OUT_JSON=$(osmosisd query gamm estimate-swap-exact-amount-in $OSMO_POOL_ID "$TOKEN_OUT" "$TOKEN_AMOUNT_IN$TOKEN_IN" --swap-route-denoms "$TOKEN_OUT" --swap-route-pool-ids $OSMO_POOL_ID --chain-id $OSMO_CHAIN_ID --node $OSMO_RPC --output json 2>/dev/null)
    if [ -z "$TOKEN_AMOUNT_OUT_JSON" ]; then
      echo "0"
    else
      TOKEN_AMOUNT_OUT=$(echo $TOKEN_AMOUNT_OUT_JSON | jq -r '.token_out_amount')
      echo "$TOKEN_AMOUNT_OUT"
    fi
  fi
}

# Returns the amount while taking slippage in account 
calculate_slippage_amount() {
  AMOUNT="$1"
  SLIPPAGE="$2"

  echo $(bc <<< "scale=0; $AMOUNT * (100 - $SLIPPAGE) / 100")
}

swap_exact_amount_in() {
  TOKEN_IN="$1"
  TOKEN_AMOUNT_IN="$2"
  MIN_AMOUNT="$3"

  # Get token out based on token in using the pool id
  TOKEN_OUT=$(get_counter_token_in_pool "$TOKEN_IN")

  osmosisd tx gamm swap-exact-amount-in "$TOKEN_AMOUNT_IN$TOKEN_IN" $MIN_AMOUNT --swap-route-pool-ids $OSMO_POOL_ID --swap-route-denoms $TOKEN_OUT --from $OSMO_KEY --chain-id $OSMO_CHAIN_ID --node $OSMO_RPC --fees 1000uosmo --yes
}

# Get namada balance using namada client (namadac)
get_namada_balance() {
  DENOM="$1"

  if [ "$SHIELDED_BROKEN" = 'true' ]; then
    get_namada_transparent_balance "$DENOM"
  else
    get_namada_shielded_balance "$DENOM"
  fi
}

# Get namada transparent balance using namada client (namadac)
get_namada_transparent_balance() {
  DENOM=$1
  DENOM_REGEX=$(echo "$DENOM" | sed 's/\//\\\//g') # needed to prevent awk from failing over the forward slashes
  
  if [ -z $DENOM ] || [ -z $NAM_TRANSPARENT ] || [ -z $NAM_CHAIN_ID ] || [ -z $NAM_RPC ]; then
    echo "0"
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
    echo "0"
  else
    echo "$(namada client balance --chain-id $NAM_CHAIN_ID --owner $NAM_VIEWING_KEY --node $NAM_RPC 2>/dev/null | awk "/^$DENOM_REGEX/{print; exit}")" | awk -F ': ' '{print $2}'
  fi
}

transfer_ibc_osmosis() {
  RECEIVER="$1"
  DENOM="$2"
  AMOUNT="$3"
  IBC_MEMO="$4"

  osmosisd tx ibc-transfer transfer transfer "$OSMO_CHANNEL" $RECEIVER "$AMOUNT$DENOM" --memo $IBC_MEMO --from $OSMO_KEY --node $OSMO_RPC --chain-id $OSMO_CHAIN_ID --fees 1000uosmo -y
}


# IBC transfer using namada client (namadac)
transfer_ibc_namada() {
  RECEIVER="$1"
  TOKEN="$2"
  AMOUNT="$3"
  
  if [ "$SHIELDED_BROKEN" = 'true' ]; then
    transfer_transparent_ibc_namada $RECEIVER $TOKEN $AMOUNT
  else
    transfer_shielded_ibc_namada $RECEIVER $TOKEN $AMOUNT
  fi
}

# IBC transfer using namada client (namadac)
transfer_transparent_ibc_namada() {
  RECEIVER="$1"
  TOKEN="$2"
  AMOUNT="$3"
  
  namada client ibc-transfer --source $NAM_TRANSPARENT --receiver $RECEIVER --token $TOKEN --amount $AMOUNT --channel-id $NAM_CHANNEL --chain-id $NAM_CHAIN_ID --node $NAM_RPC
}

# IBC shielded transfer using namada client (namadac)
transfer_shielded_ibc_namada() {
  RECEIVER="$1"
  TOKEN="$2"
  AMOUNT="$3"
  
  namada client ibc-transfer --source $NAM_VIEWING_KEY --receiver $RECEIVER --token $TOKEN --amount $AMOUNT --channel-id $NAM_CHANNEL --chain-id $NAM_CHAIN_ID --node $NAM_RPC --gas-payer $NAM_TRANSPARENT
}

# Get denom of an IBC coin
get_ibc_denom_trace() {
  IBC_DENOM="$1"

  # Check if IBC_DENOM starts with "ibc/"
  if [[ $IBC_DENOM == ibc/* ]]; then
    IBC_HASH="${IBC_DENOM#ibc/}"
    DENOM_TRACE=$(osmosisd query ibc-transfer denom-trace "$IBC_HASH" --node $OSMO_RPC --output json)
    DENOM_TRACE_PATH=$(echo "$DENOM_TRACE" | jq -r '.denom_trace.path')
    DENOM_TRACE_BASE_DENOM=$(echo "$DENOM_TRACE" | jq -r '.denom_trace.base_denom')
    echo "$DENOM_TRACE_PATH/$DENOM_TRACE_BASE_DENOM"
  else # else we simply return without formatting
    echo "$IBC_DENOM"
  fi
}

# Generate an IBC memo for shielded transfers from counter chain to namada
gen_ibc_memo() {
  TARGET=$1
  IBC_DENOM=$2
  AMOUNT=$3

  # Get IBC denom trace
  TOKEN=$(get_ibc_denom_trace "$IBC_DENOM")

  OUTPUT=$(namada client ibc-gen-shielded --target "$TARGET" --channel-id "$NAM_CHANNEL" --token "$TOKEN" --amount "$AMOUNT" --output-folder-path ".tmp/" | grep -oP "(?<=to ).*$")
  IBC_MEMO=$(head -n 1 $OUTPUT)

  # Remove the generated file (garbage collection)
  rm $OUTPUT

  echo $IBC_MEMO
}

shielded_sync() {
  FROM_HEIGHT=$(repeat_input_number "Do you want to start the shielded sync from a specific height? [default: 0; meaning it won't run with --from-height]" "true")
  
  if [ -z "$FROM_HEIGHT" ] || [ "$FROM_HEIGHT" = "0" ]; then
    namada client shielded-sync --node $NAM_RPC
  else
    namada client shielded-sync --node $NAM_RPC --from-height "$FROM_HEIGHT"
  fi
}