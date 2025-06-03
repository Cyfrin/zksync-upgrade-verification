# ZKsync Upgrade Verification

What does the security council need to verify?

> Video Walkthrough

[![Watch the video](./img/tool-thumbnail.png)](https://www.youtube.com/watch?v=c9Gv2XdxMq8)


# Table of Contents

- [ZKsync Upgrade Verification](#zksync-upgrade-verification)
- [Table of Contents](#table-of-contents)
  - [Security council responsibilities](#security-council-responsibilities)
- [Tool - Examples](#tool---examples)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
    - [Optional Requirements](#optional-requirements)
  - [Installation](#installation)
    - [Curl](#curl)
    - [Source](#source)
    - [Devcontainer](#devcontainer)
      - [Devcontainer Prerequisites](#devcontainer-prerequisites)
      - [Devcontainer Setup](#devcontainer-setup)
    - [Docker](#docker)
      - [Prerequisites](#prerequisites)
- [Quickstart](#quickstart)
  - [Getting a proposal ID from a transaction](#getting-a-proposal-id-from-a-transaction)
  - [Getting the list of ZKsync and Ethereum transactions](#getting-the-list-of-zksync-and-ethereum-transactions)
  - [Verify the ETH proposal ID](#verify-the-eth-proposal-id)
- [Get proposal ID from a file](#get-proposal-id-from-a-file)
- [Trust Assumptions](#trust-assumptions)
- [Signature Verification](#signature-verification)
- [Testing](#testing)
- [Thank you!](#thank-you)


## Security council responsibilities
1. Pre-vote
   1. Make sure the proposal makes sense 
      1. Is it audited? Does it need to be? By whom?
   2. Make sure the proposal ID in tally is correct
   3. Make sure the list of upgrade calldatas reflect what the proposal describes
2. Post-vote
   1. Make sure the ETH proposal ID is correct, approve it if so
   2. Make sure when you sign, your signature reflects the proposal ID

This repo and tool will help you do everything except `2.2` (coming soon...)

# Tool - Examples

You can run any of these. 

```bash
# ZIP-4 get all the calls based off the proposal transaction
zkgov-check get-upgrades 0x50e420474a6967eaac87813fe6479e98ae8d380fd9b3ae78bc4fedc443d9dec1 --rpc-url $ZKSYNC_RPC_URL
# ZIP-3 get the ZKsync proposal ID based off the transaction
zkgov-check get-zk-id 0x50e420474a6967eaac87813fe6479e98ae8d380fd9b3ae78bc4fedc443d9dec1 --rpc-url $ZKSYNC_RPC_URL
# ZIP-4 get the final ETH proposal ID based off the ZKsync proposal hash
zkgov-check get-eth-id 0x50e420474a6967eaac87813fe6479e98ae8d380fd9b3ae78bc4fedc443d9dec1 --rpc-url $ZKSYNC_RPC_URL
# ZIP-4 get the final ETH proposal ID based off the ZKsync proposal hash, and all the calls in a solidity contract format
zkgov-check get-eth-id 0x50e420474a6967eaac87813fe6479e98ae8d380fd9b3ae78bc4fedc443d9dec1 --rpc-url $ZKSYNC_RPC_URL --show-solidity
# ZIP-5 get the final ETH proposal ID based off an input JSON object
zkgov-check get-eth-id --from-file sample-proposal.json
```

# Getting Started 

## Requirements

*Note: these requirements are if you install it via curl or source*

- [foundry (`cast` and `chisel` in particular)](https://getfoundry.sh/)
  - You'll know you did it right if you can run `cast --version` and you see a response like `cast 0.3.0 (41c6653 2025-01-15T00:25:27.680061000Z`
- [bash](https://www.gnu.org/software/bash/)
  - You'll know you have it if you run `bash --version` and see a response like `GNU bash, version 5....`
- `ZKSYNC_RPC_URL` environment variable - a connection to a ZKsync Era Node

### Optional Requirements

If you have a linux machine, there is currently a limit on the max size of an argument that can be passed to a bash script (see [this foundry issue](https://github.com/foundry-rs/foundry/issues/5069)). To get around this, if you're passing a massive amount of calldata to be decoded, you'll also need the `uv` python package manager installed.

- [uv](https://docs.astral.sh/uv/getting-started/installation/)

## Installation

You can install the tool via CLI, or just clone the repo.

### Curl

```bash
curl -L https://raw.githubusercontent.com/cyfrin/zksync-upgrade-verification/main/install.sh | bash
```

### Source

You can run scripts directly from this repository.

```bash
git clone https://github.com/Cyfrin/zksync-upgrade-verification
cd zksync-upgrade-verification
./zkgov-check.sh --help
```

### Devcontainer

#### Devcontainer Prerequisites

- [Docker](https://www.docker.com/get-started)
- [Visual Studio Code](https://code.visualstudio.com/)
- [Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

#### Devcontainer Setup

1. Clone this repo

```bash
git clone https://github.com/Cyfrin/zksync-upgrade-verification
cd zksync-upgrade-verification
code .  # Opens VSCode
```

2. Make sure docker is running

3. Open the Command Palette (Ctrl+Shift+P or Cmd+Shift+P on macOS)

Run this:

```console
Dev Containers: Reopen in Container
```

4. Wait for the container to build and start, then run:

```bash
zkgov-check --help
```

### Docker 

#### Prerequisites

- [Docker](https://www.docker.com/get-started)

1. Build the container

```bash
git clone https://github.com/Cyfrin/zksync-upgrade-verification
cd zksync-upgrade-verification

# Build the Docker image
docker build -f .devcontainer/Dockerfile -t zkgov-tool .
```

2. Run the container

```
# Interactive mode with increased stack size
docker run -it --rm \
  --ulimit stack=67108864:67108864 \
  -v $(pwd):/workspace \
  -w /workspace \
  -e ZKSYNC_RPC_URL="https://mainnet.era.zksync.io" \
  zkgov-tool \
  /bin/zsh
```

3. Run the command

```bash
zkgov-check --help
```

# Quickstart

## Getting a proposal ID from a transaction 

Take a proposal like [ZIP-4](https://www.tally.xyz/gov/zksync/proposal/101504078395073376090945455670282351844085476168544993296976152194429222258153?govId=eip155:324:0x76705327e682F2d96943280D99464Ab61219e34f). We want to start with the transaction that initialized this proposal. Click the three dots next to the `Published onchain` section of the Tally UI, and view on block explorer. 

<p align="center">
        <img src="img/zip-4-ui.png" width="400" alt=""/></a>
</p>

Get the transaction, and make sure the Tally UI matches with:

```bash
zkgov-check get-zk-id 0x5e7ef52948f372de0a64c19e76a30313f2b6b1e4b4b63791eb0fcac68a565604 --rpc-url $ZKSYNC_RPC_URL
```

You'll get:
```
Proposal ID
Hex: 0xe06945bf075531a14f242e27d67a16129ba4df93565ef0ac2c4fd78b01d605e9
Decimal: 101504078395073376090945455670282351844085476168544993296976152194429222258153
```

And the `Decimal` is correct.

## Getting the list of ZKsync and Ethereum transactions

A DAO proposal is a list of targets, values, and calldatas. We should verify what targets we are calling with what calldata. There are special cases, when we call `sendToL1(bytes)`. When we do this, we are likely performing an Upgrade. An Upgrade can consist of many targets, values, and calldatas themselves, so we want to check those out. You can see the exhaustive list of ZKsync transactions (and, if they call `sendToL1`, the corresponding Ethereum transactions) with:

```bash
zkgov-check get-zk-id 0x50e420474a6967eaac87813fe6479e98ae8d380fd9b3ae78bc4fedc443d9dec1 --rpc-url $ZKSYNC_RPC_URL
```

This will give an output like:

```
ZKsync Transactions

ZKsync Transaction #1:
Target Address: 0x0000000000000000000000000000000000008008
Value: 0
Calldata: 0x62f84b24000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000005d8ba173dc6c3c90c8f7c04c9288bef5fdbad06e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000024f34d18680000000000000000000000000000000000000000000000000000000000002a3000000000000000000000000000000000000000000000000000000000
(ETH transaction)

Ethereum Transaction #1

  Call:
    Target: 0x5D8ba173Dc6C3c90C8f7C04C9288BeF5FDbAd06E
    Value: 0
    Calldata:  0xf34d18680000000000000000000000000000000000000000000000000000000000002a30

Executor: 0x0000000000000000000000000000000000000000
Salt: 0x0000000000000000000000000000000000000000000000000000000000000000
```

## Verify the ETH proposal ID

The proposal ID on Ethereum is different from the one on ZKsync, but we can generate it and make sure it's the same one by hashing the values the same way we do on Ethereum. As of today this is a two step process, because I am coding at 1 in the morning. If someone wants to make this a one step process, please make a PR!

```
zkgov-check get-eth-id 0x5e7ef52948f372de0a64c19e76a30313f2b6b1e4b4b63791eb0fcac68a565604 --rpc-url $ZKSYNC_RPC_URL
```

This will give an output like:

```
Ethereum proposal ID #1: 0xb2a2b1d022c7d3e6c8864abca83334183918a4f62c6b9741a8108b645fe52c1e
```

If you'd like to see what all the calldata looks like in a solidity contract, you can add `--show-solidity` to see:

```solidity
/*//////////////////////////////////////////////////////////////
                              CONTRACT 1
//////////////////////////////////////////////////////////////*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {IProtocolUpgradeHandler} from "src/interfaces/IProtocolUpgradeHandler.sol";
import {Test, console} from "forge-std/Test.sol";

contract ZIPTest_eth_1 {
    bytes32 public salt = 0x0000000000000000000000000000000000000000000000000000000000000000;
    IProtocolUpgradeHandler.Call[] public calls;

    IProtocolUpgradeHandler.Call call1 = IProtocolUpgradeHandler.Call({
        target: 0x5D8ba173Dc6C3c90C8f7C04C9288BeF5FDbAd06E,
        value: 0,
        data: hex"f34d18680000000000000000000000000000000000000000000000000000000000002a30"
    });

    constructor() {
        calls.push(call1);
    }

    function getHash() public view returns (bytes32) {
        IProtocolUpgradeHandler.UpgradeProposal memory upgradeProposal = IProtocolUpgradeHandler.UpgradeProposal({
            calls: calls,
            salt: salt,
            executor: 0x0000000000000000000000000000000000000000
        });
        return keccak256(abi.encode(upgradeProposal));
    }
}
contract TestZIPEth_1 is Test {
    ZIPTest_eth_1 zip;

    function setUp() public {
        zip = new ZIPTest_eth_1();
    }

    function testZIPEthProposalId_1() public view {
        bytes32 hash = zip.getHash();
        console.logBytes32(hash);
    }
}
```

```console
Total ETH transactions (and therefore, contracts): 1
Please copy paste the contract you're looking for the signature for into the test folder, and run the main test with:
  forge test --mt getHash --mc (contract_name) -vv
```

You can then copy the `solidity` code into the `test` folder, and run the test that was given to you to see the resulting signature.

```
forge test --mt testZIPEthProposalId_1 --mc TestZIPEth_1 -vv
```

# Get proposal ID from a file

You can also get the proposal ID from a file. The file should look like:

```json
{
    "executor": "0xECE8e30bFc92c2A8e11e6cb2e17B70868572E3f6",
    "salt": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "calls": [
        {
            "target": "0x303a465b659cbb0ab36ee643ea362c509eeb5213",
            "value": "0x00",
            "data": "0x79ba5097"
        },
        {
            "target": "0xc2ee6b6af7d616f6e27ce7f4a451aedc2b0f5f5c",
            "value": "0x00",
            "data": "0x79ba5097"
        },
        {
            "target": "0xd7f9f54194c633f36ccd5f3da84ad4a1c38cb2cb",
            "value": "0x00",
            "data": "0x79ba5097"
        },
        {
            "target": "0x5d8ba173dc6c3c90c8f7c04c9288bef5fdbad06e",
            "value": "0x00",
            "data": "0x79ba5097"
        },
        {
            "target": "0xf553e6d903aa43420ed7e3bc2313be9286a8f987",
            "value": "0x00",
            "data": "0x79ba5097"
        }
    ]
}
```

And you can run:

```
zkgov-check get-eth-id --from-file sample-proposal.json
```

To get:

```
Ethereum Proposal ID
Proposal ID: 0xa34bdc028de549c0fbd0374e64eb5977e78f62331f6a55f4f2211348c4902d13
Encoded Proposal: 0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000060000000000000000000000000ece8e30bfc92c2a8e11e6cb2e17b70868572e3f60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000001e000000000000000000000000000000000000000000000000000000000000002800000000000000000000000000000000000000000000000000000000000000320000000000000000000000000303a465b659cbb0ab36ee643ea362c509eeb521300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000479ba509700000000000000000000000000000000000000000000000000000000000000000000000000000000c2ee6b6af7d616f6e27ce7f4a451aedc2b0f5f5c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000479ba509700000000000000000000000000000000000000000000000000000000000000000000000000000000d7f9f54194c633f36ccd5f3da84ad4a1c38cb2cb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000479ba5097000000000000000000000000000000000000000000000000000000000000000000000000000000005d8ba173dc6c3c90c8f7c04c9288bef5fdbad06e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000479ba509700000000000000000000000000000000000000000000000000000000000000000000000000000000f553e6d903aa43420ed7e3bc2313be9286a8f98700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000479ba509700000000000000000000000000000000000000000000000000000000
```

Note: If you don't pass an executor or salt, it'll default them to the null values:

```
executor="0x0000000000000000000000000000000000000000"
salt="0x0000000000000000000000000000000000000000000000000000000000000000"
```


# Trust Assumptions
- Bash
- Foundry
- My code
- Your ZKsync RPC URL

# Signature Verification

Right now, this tool doesn't show you the hash that should show up on your wallet when you sign off on the proposals. I will add that in soon. 

# Testing


```bash
bash test.sh
```

# Thank you!
