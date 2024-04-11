#!/bin/bash

# Source shared functions
source helpers/shared.sh

# Source input functions
source helpers/input.sh

# Source config
source config/get.sh

# Greeting
if [ $SHIELDED_BROKEN = 'true' ]; then
  if [ -z $NAM_IMPLICIT_KEY ]; then
    echo "Welcome, stranger!"
  else
    echo "Welcome, $(shorten_address $NAM_IMPLICIT_KEY 21 21)!"
  fi
else
  if [ -z $NAM_VIEWING_KEY ]; then
    echo "Welcome, anonymous stranger!"
  else
    echo "Welcome, $(shorten_address $NAM_VIEWING_KEY 21 21)!"
  fi
fi