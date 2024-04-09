#!/bin/bash

# Variables
UOSMO_RATIO=5
NAAN_RATIO=1

# Function to create a json file for an OSMO:NAAN pool
create_pool_json() {
  UOSMO_AMOUNT=$1
  NAAN_DENOM=$2
  NAAN_AMOUNT=$3

  echo "{
    \"weights\": \"$UOSMO_RATIO$UOSMO_DENOM,$NAAN_RATIO$NAAN_DENOM\",
    \"initial-deposit\": \"$UOSMO_AMOUNT,$NAAN_AMOUNT$NAAN_DENOM\",
    \"swap-fee\": \"0.01\",
    \"exit-fee\": \"0.01\",
    \"future-governor\": \"168h\"
  }" > .tmp/pool.json
}

read -p "What's the uosmo:naan ratio? [ex. 5:1, 5 uosmo equals 1 naan]" UOSMO_NAAN_RATIO
read -p "Enter the amount of uosmo you'll deposit (1000000 = 1OSMO): " uosmo_amount
read -p "Enter the amount of $NAM_DENOM to deposit: " naan_amount

# Set defaults
if [ -z "$naan_denom" ]; then
  naan_denom="$NAAN_IBC_DENOM"
fi

# Create the pool JSON and create the pool
create_pool_json "$uosmo_amount" "$naan_denom" "$naan_amount"
osmosisd tx gamm create-pool --chain-id $OSMO_CHAIN_ID --pool-file .tmp/pool.json --from $OSMO_ADDRESS --dry-run --log_format json #--yes

# TODO: We need to capture the created pool ID and whatever details that are important