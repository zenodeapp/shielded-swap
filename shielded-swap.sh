#!/bin/bash

# Source default variables
source ./_default_variables.sh

# Read pool data from pool-data.json

# 1. Send naan from Namada to Osmosis
read -p "Which transparent address (should be shielded, but doesn't work in SE) are you sending this from?: " namada_address
read -p "Which shielded address (znam...) should receive this?: " shielded_namada_address
read -p "Which osmosis address would you like to send this to (for transparency use a dummy address): " osmosis_address
read -p "Enter the amount of naan to send: " naan_amount

# Check osmosis address balance of the naan token (for the specified channel)

namada client ibc-transfer --source $namada_address --receiver $osmosis_address --token naan --amount $naan_amount --channel-id "channel-$COUNTER_CHANNEL_ID"

# Loop to check if osmosis_address received the amount, timeout in 2 min

# 2. Swap naan to osmo in the created pool when osmosis_address received the amount

# AMOUNT RECEIVED
$AMOUNT_RECEIVED=10

# 3. Generate IBC memo and extract it
TEMP_PATH=./temp/
namada client ibc-gen-shielded --target "$shielded_namada_address" --channel-id "channel-$COUNTER_CHANNEL_ID" --token "uosmo" --amount $naan_amount --output-folder-path $TEMP_PATH
# If we're sending NAAN instead, add this if we have enough time:
# namada client ibc-gen-shielded --target "$shielded_namada_address" --channel-id "channel-$COUNTER_CHANNEL_ID" --token "transfer/$CHANNEL_ID/tnam1qxvg64psvhwumv3mwrrjfcz0h3t3274hwggyzcee" --amount $naan_amount --output-folder-path  $TEMP_PATH
$IBC_MEMO=24042

# 4. Send received osmosis amount back to namada_address
osmosisd tx ibc-transfer transfer transfer "channel-$CHANNEL_ID" $shielded_namada_address "$AMOUNT_RECEIVED"uosmo --memo $IBC_MEMO --from $OSMO_KEY --node https://osmosis-testnet-rpc.polkachu.com:443 --chain-id osmo-test-5 --fees 1000uosmo

# 5. Check if expected osmo is received