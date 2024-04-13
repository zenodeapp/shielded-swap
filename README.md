# Shielded Swap (CLI based)

A CLI BASED SHIELDED SWAP application for SE.

This has been written by ZENODE and is licensed under the MIT-license (see [LICENSE](./LICENSE)).

> [!TIP]
> If you need to send funds over from Osmosis to Namada or vice versa, head over to https://zenode.app/explorer/namada/ibc.
>
> This is a partially-working web-based Shielded IBC application (Transparent transfers work + shielded OSMO/THETA to Namada).
>
> > It's also possible to fund your wallet using the _Fund your wallet(s)_ section inside the wizard.

## Requirements
- [gum](https://github.com/charmbracelet/gum)
- [osmosisd](https://docs.osmosis.zone/osmosis-core/osmosisd)
- [namada](https://docs.namada.net/introduction/install)
- [jq](https://jqlang.github.io/jq/download)
- [bc](https://www.gnu.org/software/bc/manual/html_mono/bc.html)

## Features

 ### General
- Written in a modular fashion to promote reusability of code
- Attempted to add as much error-handling and validity checks as possible for robustness (e.g. user input validation, type errors, etc.)
- Configure the config.json file from within the wizard (plus auto-validity checker implemented)
- Namada chain ID can be configured (not exclusively tied to SE)

### Shielded
- Able to perform shielded-swaps between _naan <=> uosmo_ (shielded actions)
- Configure _slippage_ for shielded swaps
- Swaps are simulated and give an approximate for the min. amount of tokens the user could receive
- Able to shield and unshield assets (shielded actions)
- Smart shielded-syncing; indicates whenever a shielded-sync should be performed
- Compatible with broken shielded namada-chains (SE) by enabling the `shieldedBroken`-key in [config.json](config.json). See more about this in section [shieldedBroken](#shieldedbroken) or [Flow of action](#flow-of-action).

 ### Pools
- Allows for a simple way to _create naan-uosmo pools_
- List all osmosis pools the user is a part of (for quickly switching between created pools)
- Show information for the selected pool

### Balance
- Balance checker for osmosis, transparent and shielded addresses
- Able to fund your linked osmosis or namada wallet with, respectively, naan or uosmo
- Creating new transparent, shielded (viewing key + payment combined) and osmosis keys made easy


## Quick-start

### 1. Install jq and bc

> [!NOTE]
>
> Likely already installed!
>

```
sudo apt-get install jq bc
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

> Or, see: https://docs.osmosis.zone/osmosis-core/osmosisd.

### 4. Install namada

> See: https://docs.namada.net/introduction/install.

### 5. Run the wizard!

```
bash wizard.sh
```

## Configuration

> [!TIP]
>
> Most of the [config.json](config.json) file is already pre-filled with data one could make use of. The only values you will have to change are:
> - `namImplicitKey`: _alias_
> - `namTransparent`: _address_
> - `namViewingKey`: _alias_
> - `namPayment`: _address_
> - `osmoKey`: _alias_
> - `osmoAddress`: _address_
>
> You can make these changes using the wizard. See below for more info or check out the [_config.example.json](/config/_config.example.json)-file for an example.

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

  "namImplicitKey": alias,
  "namTransparent": address,
  "namViewingKey": alias,
  "namPayment": address,
  "namMemo": string,

  "osmoKey": alias,
  "osmoAddress": string
}
```
> `alias` and `address` are both strings but should explicitly be _aliases_ or _addresses_! 

#### shieldedBroken

`shieldedBroken` should only be set to `true` if the Namada chain isn't able to perform a _shielded_ IBC transfer to an external chain (the reject VP issue). What this does is tell the wizard to instead use the _transparent address_ for the **initial transfer** of _naan/uosmo from Namada_ to Osmosis.

#### namRpc and osmoRpc

Make sure to also include the port number for `osmoRpc`, else `osmosisd` won't let transactions through. Possibly also the case for `namRpc`.

#### namImplicitKey and namTransparent

Make sure to let these two point to the same address.

#### osmoKey and osmoAddress

Make sure to let these two point to the same address.

## Appendix

### Channels/pools

#### Existing
I already created the following channels and pools that can be used:
- ibc `channel-1321 <=> channel-6903`
- ibc/denom `ibc/F6EE42E1CC8154EFDC3329174F4A519DCB6C62BAC914DC55B1E624C0BD07880F`
- pool(s) `445` or `447`

#### New

If you need to create a new pool, I usually used the following settings:
- A ratio of 5:1
- 1000000000 uosmo (1000 OSMO) and
- 200 naan

> This seems to work well for me; just make sure not to create _too small pools_ or try to swap _too little amounts_, else shielded swaps will fail.

### Shielded-sync

> [!CAUTION]
>
> If you have an automated script running for keeping your shielded-sync up-to-date, then do not perform any shielded-sync's inside of the wizard itself! There's a chance of corrupting your cached data when multiple shielded-sync runs are executed at the same time!
>
> The wizard makes sure to always ask for your consent when it wants to run this command.

### Flow of action

This is an overall explanation of what happens during a shielded-swap. Details like configuring slippage, balance checking and error-handling have been omitted but can be experienced in the wizard or seen in the code itself (mostly in [layout/shielded.sh](layout/shielded.sh)).

1. Depending on whether `shieldedBroken` is `true` or `false` tokens get send from a **transparent** or **shielded** Namada address to Osmosis address.
2. Once this arrives on Osmosis, a swap is performed; either **uosmo => naan or naan => uosmo**.
3. After this swap succeeds, a memo gets generated in preparation for sending the tokens back to a Namada **shielded** wallet.
4. The IBC transfer gets executed and the user is given the option to perform a shielded sync and check their updated balance.

### Ideas

- Swapping of any type of token, not just naan <=> uosmo pairs would have been possible if I refactored the code further. The wizard depends mostly on which pool is selected, thus treating this as the indicator to which two tokens the user wanted to swap would have been feasible!
- Implementing more tutorial-like workflows for changing the [config](config.json)-file would have made it easier to get started.
- The [config](config.json)-file is currently quite bloated. Some values could have been fetched and stored into an auto-generated static-config.json file (e.g. like deriving `osmoAddress` from the `osmoKey` and `namTransparent` from the `namImplicitKey`).
- [Issue #1](https://github.com/zenodeapp/shielded-swap/issues/1)
- [Issue #2](https://github.com/zenodeapp/shielded-swap/issues/2)

</br>

<p align="right">— ZEN</p>
<p align="right">Copyright (c) 2024 ZENODE</p>
