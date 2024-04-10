# Shielded Swap (CLI based)

An attempt to create a shielded-swap CLI variant for SE.

This has been written by ZENODE and is licensed under the MIT-license (see [LICENSE](./LICENSE)).

## Requirements
- [gum](https://github.com/charmbracelet/gum)
- [osmosisd](https://docs.osmosis.zone/osmosis-core/osmosisd)
- [namada](https://docs.namada.net/introduction/install)
- [jq](https://jqlang.github.io/jq/download)
- [bc](https://jqlang.github.io/jq/download)

## Features
- Able to perform shielded-swaps between `naan <=> uosmo` (shielded action)
- Allows for a simple way to `create naan-uosmo pools`
- Lists all osmosis pools the user is a part of (for quickly switching between created pools)
- Shows selected pool information
- Configuration of the slippage for shielded swaps
- Swaps are simulated and give an approximate for the min. amount of tokens the user could receive
- Namada chain ID can be configured (not exclusively tied to SE)
- Compatible with broken shielded namada-chains (SE); enabling the `shieldedBroken`-key in [config.json](config.json) lets shielded-swaps perform the **first step** of the action flow using the transparent address
- Simple method to call a shielded-sync before fetching balances
- Shows balances for osmosis, transparent and shielded addresses
- Written in a modular fashion to promote reusability of code
- Added error-handling for robustness

## Quick-start

### 1. Install jq and bc

> [!NOTE]
>
> Likely already installed!
>

```
sudo apt-get install jq
```

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

## Configuration

> [!TIP]
>
> **Quick-start**
>
> Most of the [config.json](config.json) file is already pre-filled with data one could already make use of. The only values you will have to change are:
> - `namTransparent`
> - `namViewingKey`
> - `namShielded`
> - `osmoKey`
> - `osmoAddress`
>
> You can make these changes using the wizard, but it might be useful to know what the values should look like. See below for more info or check out the [_config.example.json](/config/_config.example.json)-file for an example.

### Schema
```
{
  "shieldedBroken": boolean,
  "namChainId": string,
  "osmoChainId": string,
  "namRpc": string,
  "osmoRpc": string,

  "osmoPoolId": number,
  "namDenom": string,
  "namIbc": string,
  "namChannel": string,
  "osmoChannel": string,

  "namTransparent": alias,
  "namViewingKey": alias,
  "namShielded": address,

  "osmoKey": alias,
  "osmoAddress": string
}
```
> `alias` and `address` are both strings but should explicitly be _aliases_ or _addresses_! 

#### shieldedBroken

`shieldedBroken` should only be set to `true` if the Namada chain isn't able to perform a _shielded_ IBC transfer to an external chain (the reject VP issue). What this does is tell the wizard to use the _transparent address_ for the **initial transfer** of NAAN/OSMO from Namada to Osmosis instead.

#### namRpc and osmoRpc

Make sure to also include the port number for `osmoRpc`, else `osmosisd` won't let transactions through. Possibly also the case for `namRpc`.

#### osmoKey and osmoAddress

Make sure to let these two point to the same address.

</br>

<p align="right">— ZEN</p>
<p align="right">Copyright (c) 2024 ZENODE</p>
