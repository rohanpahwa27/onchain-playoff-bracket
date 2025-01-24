# Introduction to Solidity

## Installation

Install `foundryup`
```
curl -L https://foundry.paradigm.xyz | bash
```

Install foundry toolchain (`forge`, `cast`, `anvil`, `chisel`)
```
foundryup
```

## Create a new project

```
forge init
```

## Build

Compile contracts to surface build issues.
```
forge build
```

Format contracts according to the official [Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html).
```
forge fmt
```

## Deploy

Create a CLI account
```
cast wallet new
```

Encrypt this CLI account and store within foundry
```
cast wallet import --private-key [generated private key] --name [e.g. "dev"]
```

Send testnet ETH to your CLI account

Run a script
```
forge script [script contract name] --rpc-url "https://sepolia.base.org" --account [CLI account name] --sender [CLI account address] --broadcast -vvvv
```

Run a script that verifies deployed contracts
```
forge script [script contract name] --rpc-url "https://sepolia.base.org" --account [CLI account name] --sender [CLI account address]  --broadcast -vvvv --verify --verifier-url "https://api-sepolia.basescan.org/api" --etherscan-api-key $BASESCAN_API_KEY
```