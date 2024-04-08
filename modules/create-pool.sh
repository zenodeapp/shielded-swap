#!/bin/bash

# Source default variables
source ../_default_variables.sh

# Function to create a json file for a 5:1 pool for OSMO:NAAN
create_pool_json() {
  UOSMO_DENOM=uosmo
  UOSMO_AMOUNT=$1
  NAAN_DENOM=$2
  NAAN_AMOUNT=$3

  echo "{
    \"weights\": \"5$UOSMO_DENOM,1$NAAN_DENOM\",
    \"initial-deposit\": \"$UOSMO_AMOUNT,$NAAN_AMOUNT$NAAN_DENOM\",
    \"swap-fee\": \"0.01\",
    \"exit-fee\": \"0.01\",
    \"future-governor\": \"168h\"
  }" > ./pool.json
}

echo "Welcome to the Osmosis Pool Creation Wizard!"
read -p "Enter the amount of uosmo you'll deposit (1000000 = 1OSMO): " uosmo_amount
read -p "Enter the ibc denomination for naan (ibc/1EAE32...) [default: $NAAN_IBC_DENOM]: " naan_denom
read -p "Enter the amount of $naan_denom to deposit: " naan_amount

# Set defaults
if [ -z "$naan_denom" ]; then
  naan_denom="$NAAN_IBC_DENOM"
fi

# Create the pool JSON and create the pool
create_pool_json "$uosmo_amount" "$naan_denom" "$naan_amount"
osmosisd tx gamm create-pool --chain-id osmo-test-5 --pool-file ./pool.json --from $OSMO_KEY --log_format json --yes

# TODO: We need to capture the created pool ID and whatever details that are important

create_pool_data_json() {
  # TODO: create a file containing info like the ibc/denom, the channel we're using etc.
}