#!/bin/bash

# Root of the current repository
REPO_ROOT=$(cd "$(dirname "$0")" && pwd)

# Source default variables
source $REPO_ROOT/_default_variables.sh

# Variables
UOSMO_DENOM=uosmo
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
  }" > $REPO_ROOT/pool.json
}

read -p "Enter the amount of uosmo you'll deposit (1000000 = 1OSMO): " uosmo_amount
read -p "Enter the ibc denomination for naan (ibc/1EAE32...) [default: $NAAN_IBC_DENOM]: " naan_denom
read -p "Enter the amount of $naan_denom to deposit: " naan_amount

# Set defaults
if [ -z "$naan_denom" ]; then
  naan_denom="$NAAN_IBC_DENOM"
fi

# Create the pool JSON and create the pool
create_pool_json "$uosmo_amount" "$naan_denom" "$naan_amount"
osmosisd tx gamm create-pool --chain-id osmo-test-5 --pool-file $REPO_ROOT/pool.json --from $OSMO_KEY --log_format json #--yes

# TODO: We need to capture the created pool ID and whatever details that are important

create_pool_data_json() {
  # TODO: create a file containing info like the ibc/denom, the channel we're using etc.
}