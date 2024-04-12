# Gloom Contracts

<p align="center">
<img src="https://github.com/Gloom-Labs/contracts/assets/12901349/b4638853-8646-4d1c-9a85-add838ec9de0" width="200" height="200">
</p>

## Overview

This repository contains the following contracts:
- GloomToken.sol (OpenZeppelin ERC20)
- GloomGovernor.sol (OpenZeppelin Governor)
- GloomMigrator.sol (Burn old tokens to receive new tokens)
- OldGloom.sol (TaxableTeamToken)

GloomToken.sol is a standard ERC20 without any tax / reflections. The contract has no owner, no minting functions, no admin functions, and is not upgradable.
## Token details
- name: Gloom
- symbol: GLOOM
- decimals: 18
- total supply: 1,000,000,000 (1 billion)
- tax / reflection: 0%

## Deployed contracts

- GloomToken: [0xbb5D04c40Fa063FAF213c4E0B8086655164269Ef](https://basescan.org/address/0xbb5D04c40Fa063FAF213c4E0B8086655164269Ef#code)

- GloomGovernor: [0xFc8c580f1AfAaC016cBb45c1ced7F73F7DBa1FEc](https://basescan.org/address/0xFc8c580f1AfAaC016cBb45c1ced7F73F7DBa1FEc#code)

- GloomMigrator: [0x56A82A3DF3a909a1b4A1B0A418BdFBE7380e78fE](https://basescan.org/address/0x56A82A3DF3a909a1b4A1B0A418BdFBE7380e78fE#code)

- Old Gloom Token: [0x4Ff77748E723f0d7B161f90B4bc505187226ED0D](https://basescan.org/address/0x4Ff77748E723f0d7B161f90B4bc505187226ED0D#code)


## Setup

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```
