# Shielded swap (CLI based)

An attempt to create a shielded-swap CLI variant for SE.

This has been written by ZENODE and is licensed under the MIT-license (see [LICENSE](./LICENSE)).

> [!CAUTION]
> This is a work in progress!

## Requirements
- [gum](https://github.com/charmbracelet/gum)
- [osmosisd](https://docs.osmosis.zone/osmosis-core/osmosisd)
- [namada](https://docs.namada.net/introduction/install)

## Quick-start

### 1. Install gum

```
go install github.com/charmbracelet/gum@latest
```

> For other methods to install gum, see: https://github.com/charmbracelet/gum.

### 2. Install osmosisd

```
curl -sL https://get.osmosis.zone/install > i.py && python3 i.py
```

### 3. Install namada

See: https://docs.namada.net/introduction/install.

### 4. Run the wizard!

```
bash ./wizard.sh
```

## Configuration schema

You can make changes to the configurations ([config/config.json](/config/config.json)) using the wizard, but it might be useful to know what it should look like:

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

See the [config.example.json](/config/config.example.json)-file for an example on what the keys should have as values. Here below follows some extra information for certain key(s):

#### shieldedBroken

`shieldedBroken` should only be set to `true` if the Namada chain isn't able to perform a _shielded_ IBC transfer to an external chain (the reject VP issue). What this does is tell the wizard to use the _transparent address_ for the initial transfer of NAAN/OSMO from Namada to Osmosis instead.

#### namRpc and osmoRpc

Make sure to also include the port number for `osmoRpc`, else `osmosisd` won't let transactions through. Possibly also the case for `namRpc`.

</br>

<p align="right">— ZEN</p>
<p align="right">Copyright (c) 2024 ZENODE</p>
