# ZKsync Upgrade Verification

This repo is aimed at doing two things:

1. Helping the ZKsync security council verify a proposal "looks correct" so that voting and upgrading can be fast and not a "last minute thing"
2. It outlines one way to [verify an upgrade's proposal integrity](https://github.com/zksync-association/zksync-upgrade-verification-tool/tree/main/apps/web/docs/standardUpgradeDocs#step-3-verify-upgrade-proposal-integrity) as outlined in the [ZKsync upgrade documentation](https://github.com/zksync-association/zksync-upgrade-verification-tool/tree/main/apps/web/docs/standardUpgradeDocs)

# Getting Started

## Prerequisites

You have two options on how to use this repo:

### Remix Prerequisites

For using this with remix, you need only an internet connection and a browser.

### Foundry Prerequisites

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`

## Setup

### Remix Setup

https://remix.ethereum.org/#url=https://github.com/Cyfrin/zksync-upgrade-verification/src/UpgradeChecker.sol

Click this link which will load `UpgradeChecker.sol` into remix.

### Foundry Setup

```
git clone https://github.com/Cyfrin/zksync-upgrade-verification
cd zksync-upgrade-verification
forge build
```

# Step-by-step Instructions

Take a proposal like [ZIP-4](https://www.tally.xyz/gov/zksync/proposal/101504078395073376090945455670282351844085476168544993296976152194429222258153?govId=eip155:324:0x76705327e682F2d96943280D99464Ab61219e34f)

```
git clone https://github.com/Cyfrin/zksync-upgrade-verification
cd zksync-upgrade-verification
forge build
```
