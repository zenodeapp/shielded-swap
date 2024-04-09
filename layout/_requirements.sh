#!/bin/bash

# Source shared functions
source helpers/shared.sh

# Spinner animation
gum spin --spinner dot --title "Checking required commands..." -- sleep 0.5

# Required commands
osmosis_available=$(command_available "osmosisd")
namada_available=$(command_available "namada")
jq_available=$(command_available "jq")

echo "## Requirements:
|Name                 |Installed             |Installation                                       |
|---------------------|----------------------|---------------------------------------------------|
|osmosisd             |$osmosis_available    |'https://docs.osmosis.zone/osmosis-core/osmosisd'  |
|namada               |$namada_available     |'https://docs.namada.net/introduction/install'     |
|jq                   |$jq_available         |'https://jqlang.github.io/jq/download/'            |
" | gum format

echo ""

# Check if all required commands are available, else abort wizard.
if [ $osmosis_available = "YES" ] && [ $namada_available = "YES" ] && [ $jq_available = "YES" ]; then
  echo ':heavy_check_mark:  Commands are ready!' | gum format -t emoji
  gum confirm 'Are you ready to start?' && echo "" || { echo "Wizard aborted."; exit 1; }
else
  echo ":x: Can't continue, sadly not all required commands are available!" | gum format -t emoji
  echo "   Make sure to install them before continuing."
  exit 1
fi