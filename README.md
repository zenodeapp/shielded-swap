# Shielded swap (CLI based)

An attempt to create a shielded-swap CLI variant for SE.

This has been written by ZENODE and is licensed under the MIT-license (see [LICENSE](./LICENSE)).

> [!CAUTION]
> This is a work in progress!

## Requirements
- [gum](https://github.com/charmbracelet/gum)
- [osmosisd](https://docs.osmosis.zone/osmosis-core/osmosisd)
- [namada](https://docs.namada.net/introduction/install)
- [jq](https://jqlang.github.io/jq/download)

## Features
- Allows for a simple way to create naan-osmosis pools
- Lists all osmosis pools you own (for quickly switching between created pools)
- Shows balances for osmosis, transparent and shielded addresses
- Shows pool information
- Written in a modular fashion to promote reusability of code
- Attempted to add error-handling for robustness
- _WIP: swapping of naan to uosmo_
- _WIP: swapping of uosmo to naan_
- _WIP: Tutorial-like workflows_
- _WIP: compatibility with both 'broken' shielded namada-chains and 'normal' functioning ones._
- _WIP: Smart shield-syncing; with a locking mechanism to prevent corruption._
- _IDEA: Allow swapping of any type of token depending on the selected pool (not just naan-uosmo)._

## Quick-start

### 1. Install jq

```
sudo apt-get install jq
```

> For other methods to install jq, see: https://jqlang.github.io/jq/download.

### 2. Install gum

```
go install github.com/charmbracelet/gum@latest
```

> For other methods to install gum, see: https://github.com/charmbracelet/gum.

### 3. Install osmosisd

```
curl -sL https://get.osmosis.zone/install > i.py && python3 i.py
```

### 4. Install namada

> See: https://docs.namada.net/introduction/install.

### 5. Run the wizard!

```
bash ./wizard.sh
```

## Configuration schema

You can make changes to the configurations ([config.json](/config.json)) using the wizard, but it might be useful to know what it should look like:

### Typing
```
{
  "shieldedBroken": boolean,
  "namChainId": string,
  "osmoChainId": string,
  "namRpc": string,
  "osmoRpc": string,
  "namTransparent": string,
  "namShielded": string,
  "namViewingKey": string,
  "osmoAddress": string,
  "namDenom": string,
  "namAddress": string,
  "namIbc": string,
  "namChannel": string,
  "osmoChannel": string,
  "osmoPoolId": number
}
```

### Format

See the [_config.example.json](/config/_config.example.json)-file for an example on what the keys should have as values. Here below follows some extra information for certain key(s):

#### shieldedBroken

`shieldedBroken` should only be set to `true` if the Namada chain isn't able to perform a _shielded_ IBC transfer to an external chain (the reject VP issue). What this does is tell the wizard to use the _transparent address_ for the initial transfer of NAAN/OSMO from Namada to Osmosis instead.

#### namRpc and osmoRpc

Make sure to also include the port number for `osmoRpc`, else `osmosisd` won't let transactions through. Possibly also the case for `namRpc`.

</br>

<p align="right">— ZEN</p>
<p align="right">Copyright (c) 2024 ZENODE</p>
