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
$ forge script Deploy --rpc-url "https://sepolia.base.org" --account onchain-playoff-bracket --sender $WALLET_ADDRESS  
--broadcast -vvvv --verify --verifier-url "https://api-sepolia.basescan.org/api" --etherscan-api-key $BASESCAN_API_KEY
currently used smart contract: https://sepolia.basescan.org/address/0xb2fe96df7d8e2d8dbdddb98cfb76503c7eb43bea#readContract


forge script Deploy --rpc-url "https://sepolia.base.org" --account onchain-playoff-bracket --sender $WALLET_ADDRESS  --broadcast -vvvv

forge script Deploy --rpc-url "https://sepolia.base.org" --keystore /Users/rohanpahwa/.foundry/keystores/onchain-playoff-bracket/6e702d12-4850-4211-86b1-a5fe8592c725 --sender $WALLET_ADDRESS --broadcast -vvvv
```

### Contract Verification

After deploying your contract, you can verify it on block explorers for transparency and easier interaction.

#### Option 1: Blockscout (Recommended)
Blockscout is reliable for Base networks and doesn't require an API key:

```shell
$ forge verify-contract <CONTRACT_ADDRESS> contracts/SportsBetting.sol:SportsBetting --verifier blockscout --verifier-url "https://base-sepolia.blockscout.com/api"
```

#### Option 2: Basescan (Using Etherscan V2 API)
To verify on Basescan, you need an Etherscan API key (not Basescan API key) due to the V2 migration:

1. Create an account on [Etherscan.io](https://etherscan.io)
2. Generate an API key
3. Use the V2 endpoint:

```shell
$ forge verify-contract <CONTRACT_ADDRESS> contracts/SportsBetting.sol:SportsBetting --rpc-url "https://sepolia.base.org" --verifier-url "https://api.etherscan.io/v2/api?chainid=84532" --etherscan-api-key <YOUR_ETHERSCAN_API_KEY>
```

**Note**: Base Sepolia chain ID is `84532`. For more details on the V2 migration, see: https://docs.etherscan.io/v2-migration

#### Current Deployed Contract
- **Address**: `0xbb3466a0a474d085511558ba4c3b1bb61a252faf`
- **Network**: Base Sepolia
- **Blockscout**: https://base-sepolia.blockscout.com/address/0xbb3466a0a474d085511558ba4c3b1bb61a252faf
- **Basescan**: https://sepolia.basescan.org/address/0xbb3466a0a474d085511558ba4c3b1bb61a252faf

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


```
do you see anything wrong with the implementation of @SportsBetting.sol ?


I want to allow someone to create a group using an entry fee, league name, league password. any address can join if they know the league name + password and they have tp provide a username. there should be a group leaderboard where you get the scores, preductions of each player by providing the league name + password. when brackets are paused, it should show the predictions + scores. When they're not paused, they should show only the basic data like addresses + names.
```