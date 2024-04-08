#!/bin/bash

# Check if gum is installed, else we can't even run the wizard.
if ! command -v "gum" >/dev/null 2>&1; then
  echo "Gum is required to run this wizard!"
  echo "Use 'go install github.com/charmbracelet/gum@latest' or see: https://github.com/charmbracelet/gum#installation for more details."
  exit 1
fi

# Import gum styling
source _styling.sh

# Introduction
gum style	--border rounded \
	'# SHIELDED SWAP WIZARD' \
  '' \
  'Scripted by ZEN; utilizing the gum tool by charmbracelet.' \
  'See: https://github.com/zenodeapp/shielded-swap and' \
  'https://github.com/charmbracelet/gum for more info.'


# Check requirements
bash _requirements.sh

# Menu should appear for a couple of things one could do.
# - Configuring some default values
# - Creating an osmosis pool
# - Doing a shielded swap

# - Checking balances for transparent/shielded address or osmosis address.
# It should also give a summary for the configured addresses. Perhaps give a dashboard already with the balances.
# Also create a button that could refresh the balances. Incorporate shielded sync into this with a locking mechanism to prevent corruption?
