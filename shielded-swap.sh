#!/bin/bash

# Read pool data from pool-data.json

# 1. Send naan from Namada to Osmosis
read -p "Which transparent address (should be shielded, but doesn't work in SE) are you sending this from?: " namada_address
read -p "Which shielded address (znam...) should receive this?: " shielded_namada_address
read -p "Which osmosis address would you like to send this to (for transparency use a dummy address): " osmosis_address
read -p "Enter the amount of $naan_denom to send: " naan_amount

# Check osmosis address balance of the naan token (for the specified channel)

namada client ibc-transfer --source $namada_address --receiver $osmosis_address --token naan --amount $naan_amount --channel-id channel-1235

# Loop to check if osmosis_address received the amount, timeout in 2 min

# 2. Swap naan to osmo in the created pool when osmosis_address received the amount

# 3. Generate IBC memo and extract it

# 4. Send received osmosis amount back to namada_address

# 5. Check if expected osmo is received