## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script Deploy --rpc-url "https://sepolia.base.org" --account onchain-playoff-bracket --sender $WALLET_ADDRESS  --broadcast -vvvv --verify --verifier-url "https://api-sepolia.basescan.org/api" --etherscan-api-key $BASESCAN_API_KEY
```

currently used smart contract: https://sepolia.basescan.org/address/0xb2fe96df7d8e2d8dbdddb98cfb76503c7eb43bea#readContract

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
