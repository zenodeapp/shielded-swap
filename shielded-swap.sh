#!/bin/bash

# Root of the current repository
REPO_ROOT=$(cd "$(dirname "$0")" && pwd)

# Source default variables
source $REPO_ROOT/_default_variables.sh

# Read pool data from pool-data.json

# 1. Send naan from Namada to Osmosis
read -p "Which transparent address (should be shielded, but doesn't work in SE) are you sending this from?: " namada_address
read -p "Which shielded address (znam...) should receive this?: " shielded_namada_address
read -p "Which osmosis address would you like to send this to (for transparency use a dummy address): " osmosis_address
read -p "Enter the amount of naan to send: " naan_amount

# Temporary defaults start

if [ -z "$namada_address" ]; then
  namada_address="zen"
fi

if [ -z "$shielded_namada_address" ]; then
  shielded_namada_address="znam1qqtq5u90nvgq7x0pvfuayykg34td97mjs8p0x333e90rvq5e0lhs43m0gpaxh3pvkqqdpdsjxv83n"
fi

if [ -z "$osmosis_address" ]; then
  osmosis_address="osmo1j73g96rdw2vlwvkuu733tcejzyvhkp4nlsdptg"
fi

if [ -z "$naan_amount" ]; then
  naan_amount="10"
fi

# Temporary defaults end

# Choose which token to send (for now naan)
TOKEN=naan

# Check osmosis address balance of the naan token (for the specified channel)
# namada client balance --owner zen | awk '/^naan/{print; exit}'
namada client ibc-transfer --source $namada_address --receiver $osmosis_address --token "$TOKEN" --amount $naan_amount --channel-id "channel-$COUNTER_CHANNEL_ID"

# Loop to check if osmosis_address received the amount, timeout in 2 min

# 2. Swap naan to osmo in the created pool when osmosis_address received the amount


# AMOUNT RECEIVED
AMOUNT_RECEIVED=10

# 3. Generate IBC memo and extract it
# source $REPO_ROOT/_ibc-memo.sh

# echo ""
# echo "Generating IBC memo..."
# IBC_MEMO=$(gen_ibc_memo "$shielded_namada_address" "uosmo" "$AMOUNT_RECEIVED") # call with naan if we do it the other way around
# echo "Generated: $IBC_MEMO"
# echo ""

# 4. Send received osmosis amount back to namada_address
# echo Sending "$AMOUNT_RECEIVED"uosmo to $shielded_namada_address...
# osmosisd tx ibc-transfer transfer transfer "channel-$CHANNEL_ID" $shielded_namada_address "$AMOUNT_RECEIVED"uosmo --memo $IBC_MEMO --from $OSMO_KEY --node https://osmosis-testnet-rpc.polkachu.com:443 --chain-id osmo-test-5 -y --fees 1000uosmo

# 5. shielded sync

# 6. Check if uosmo balance got through