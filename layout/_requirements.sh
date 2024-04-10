#!/bin/bash

# Source shared functions
source helpers/shared.sh

# Source input functions
source helpers/input.sh

# Spinner animation
gum spin --title "Checking required commands..." -- sleep 0.5

# Required commands
osmosis_available=$(command_available "osmosisd")
namada_available=$(command_available "namada")
jq_available=$(command_available "jq")
bc_available=$(command_available "bc")

echo "## Requirements:
|Name                 |Installed             |Installation                                       |
|---------------------|----------------------|---------------------------------------------------|
|osmosisd             |$osmosis_available    |'https://docs.osmosis.zone/osmosis-core/osmosisd'  |
|namada               |$namada_available     |'https://docs.namada.net/introduction/install'     |
|jq                   |$jq_available         |'https://jqlang.github.io/jq/download'             |
|bc                   |$bc_available         |'sudo apt-get install bc'                          |
" | gum format

echo ""

# Check if all required commands are available, else abort wizard.
if [ $osmosis_available = "YES" ] && [ $namada_available = "YES" ] && [ $jq_available = "YES" ] && [ $bc_available = "YES" ]; then
  echo_success 'Commands are installed!'
  echo ""
else
  echo_fail "Can't continue, sadly not all required commands are available!"
  echo "   Make sure to install them before continuing."
  exit 1
fi