#!/bin/bash

# Root of the current repository
REPO_ROOT=$(cd "$(dirname "$0")" && pwd)

# Source default variables
source $REPO_ROOT/_default_variables.sh

TMP_PATH=$REPO_ROOT/.tmp/

gen_ibc_memo() {
  TARGET=$1
  TOKEN=$2 # 'naan' or 'uosmo'
  AMOUNT=$3

  if [ $TOKEN = "uosmo" ]; then
    output=$(namada client ibc-gen-shielded --target "$TARGET" --channel-id "channel-$COUNTER_CHANNEL_ID" --token "uosmo" --amount "$AMOUNT" --output-folder-path "$TMP_PATH" | grep -oP "(?<=to ).*$")
  else
    output=$(namada client ibc-gen-shielded --target "$TARGET" --channel-id "channel-$COUNTER_CHANNEL_ID" --token "transfer/channel-$CHANNEL_ID/$NAAN_DENOM" --amount "$AMOUNT" --output-folder-path  "$TMP_PATH" | grep -oP "(?<=to ).*$")
  fi

  echo $output
}