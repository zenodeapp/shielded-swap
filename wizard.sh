#!/bin/bash

# This makes sure the entire script exits if any command fails (useful because of my modular approach to coding)
set -e

# Source shared functions
source helpers/shared.sh

# Check if gum is installed, else we can't even run the wizard.
if [ "$(command_available "gum")" = "NO" ]; then
  echo "Gum is required to run this wizard!"
  echo "Use 'go install github.com/charmbracelet/gum@latest' or see: https://github.com/charmbracelet/gum#installation for more details."
  exit 1
fi

# Import gum variables
source config/_gum.sh

# Welcome banner
bash layout/_banner.sh

# Requirements table and checker
bash layout/_requirements.sh

# Main menu
bash layout/main.sh