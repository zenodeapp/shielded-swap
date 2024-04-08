#!/bin/bash

# Introduction and requirements
gum style	--foreground 1500 --border-foreground 1500 --border double --margin "1 2" --padding "2 4" \
	'SHIELDED SWAP WIZARD' \
  '' \
  'Scripted by ZEN; utilizing the gum tool by charmbracelet.' \
  'See: https://github.com/charmbracelet/gum for more info.'


command_available() {
  if command -v "$1" &>/dev/null; then
    echo "YES"
  else
    echo "NO"
  fi
}

gum spin --spinner dot --title "Checking required commands..." -- sleep 1

osmosis_available=$(command_available "osmosisd")
namada_available=$(command_available "namada")

echo "## Requirements:
|Name                 |Installed             |Installation                                       |
|---------------------|----------------------|---------------------------------------------------|
|osmosisd             |$osmosis_available    |'https://docs.osmosis.zone/osmosis-core/osmosisd'  |
|namada               |$namada_available     |'https://docs.namada.net/introduction/install'     |
"  | gum format

echo ""

if [ $osmosis_available = "YES" ] && [ $namada_available = "YES" ]; then
  echo ':heavy_check_mark:  Commands are available!' | gum format -t emoji
  echo ""
  gum confirm 'Are you ready to start?' && echo "Starting wizard!" || { echo "Wizard aborted."; exit 1; }
else
  echo ":x: Can't continue, sadly not all required commands are available!" | gum format -t emoji
  echo "   Make sure to install them before continuing."
  exit 1
fi

# Menu should appear for a couple of things one could do.
# - Configuring some default values
# - Creating an osmosis pool
# - Doing a shielded swap

# - Checking balances for transparent/shielded address or osmosis address.
# It should also give a summary for the configured addresses. Perhaps give a dashboard already with the balances.
# Also create a button that could refresh the balances. Incorporate shielded sync into this with a locking mechanism to prevent corruption?