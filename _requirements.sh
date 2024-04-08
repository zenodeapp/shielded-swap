#!/bin/bash

command_available() {
  if command -v "$1" >/dev/null 2>&1; then
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