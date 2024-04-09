#!/bin/bash

# Exit the entire script if any command fails
set -e

# Root of the current repository
REPO_ROOT=$(cd "$(dirname "$0")" && pwd)

# Check if gum is installed, else we can't even run the wizard.
if ! command -v "gum" >/dev/null 2>&1; then
  echo "Gum is required to run this wizard!"
  echo "Use 'go install github.com/charmbracelet/gum@latest' or see: https://github.com/charmbracelet/gum#installation for more details."
  exit 1
fi

# Import gum styling
source $REPO_ROOT/config/_styling.sh

# Introduction
gum style	--border rounded --margin "1 2" --padding "2 4" \
	'# SHIELDED SWAP WIZARD' \
  '' \
  'Scripted by ZEN; utilizing the gum tool by charmbracelet.' \
  'See: https://github.com/zenodeapp/shielded-swap and' \
  'https://github.com/charmbracelet/gum for more info.'


# Check requirements
bash $REPO_ROOT/_requirements.sh

# Menu
bash $REPO_ROOT/menu/main.sh