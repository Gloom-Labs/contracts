# Gloom Token Contracts

## Overview

This repository contains the new Gloom token contract GloomToken.sol, a OpenZeppelin Governor contract GloomGovernor.sol, and a migrator contract GloomMigrator.sol.

GloomToken.sol is a standard ERC20 with 0% tax and no reflection mechanisms. For maximum transparency and full decentralization, the contract has no owner, no minting functions, and no admin functions, no upgradability. This contract is by default renounced and immutable once deployed.

- name: Gloom
- symbol: GLOOM
- decimals: 18
- total supply: 1,000,000,000 (1 billion)
- tax / reflection: 0%

For maximum transparency and decentralization, the GloomToken contract has no admin functions, no owner, no minting functions. This contract is by default renounced and immutable once deployed.

## Deployed contracts

- GloomToken: [0xbb5D04c40Fa063FAF213c4E0B8086655164269Ef](https://basescan.org/address/0xbb5D04c40Fa063FAF213c4E0B8086655164269Ef#code)

- GloomGovernor: [0xFc8c580f1AfAaC016cBb45c1ced7F73F7DBa1FEc](https://basescan.org/address/0xFc8c580f1AfAaC016cBb45c1ced7F73F7DBa1FEc#code)

- GloomMigrator: [0x56A82A3DF3a909a1b4A1B0A418BdFBE7380e78fE](https://basescan.org/address/0x56A82A3DF3a909a1b4A1B0A418BdFBE7380e78fE#code)

## Old Gloom contract

- TaxableTeamToken: [0x4Ff77748E723f0d7B161f90B4bc505187226ED0D](https://basescan.org/address/0x4Ff77748E723f0d7B161f90B4bc505187226ED0D#code)

## Setup

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```
