#!/bin/bash

if [ $SHIELDED_BROKEN = 'true' ]; then
  if [ -z $NAM_TRANSPARENT ]; then
    echo "Welcome, stranger!"
  else
    echo "Welcome, $NAM_TRANSPARENT!"
  fi
else
  if [ -z $NAM_SHIELDED ]; then
    echo "Welcome, anonymous stranger!"
  else
    echo "Welcome, $NAM_SHIELDED!"
  fi
fi