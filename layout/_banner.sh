#!/bin/bash

VERSION=v1.0.0

gum style	--border rounded --margin "1 2" --padding "2 4" \
	"# SHIELDED SWAP WIZARD ($VERSION)" \
  '' \
  'Scripted by ZEN; utilizing the gum tool by charmbracelet.' \
  'See: https://github.com/zenodeapp/shielded-swap and' \
  'https://github.com/charmbracelet/gum for more info.'

gum log --structured --level info "Use https://zenode.app/explorer/namada/ibc if you need to transfer funds between Osmosis and Namada."