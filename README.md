# ZKsync Upgrade Verification

What does the security council need to verify?

## Pre-vote
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

```bash
# ZIP-4 get all the calls based off the proposal transaction
zkgov_check get_upgrades 0x5e7ef52948f372de0a64c19e76a30313f2b6b1e4b4b63791eb0fcac68a565604 --rpc-url $ZKSYNC_RPC_URL
# ZIP-3 get the ZKsync proposal ID based off the transaction
zkgov_check get_zk_id 0x50e420474a6967eaac87813fe6479e98ae8d380fd9b3ae78bc4fedc443d9dec1 --rpc-url $ZKSYNC_RPC_URL
# ZIP-4 get the final ETH proposal ID based off the ZKsync proposal hash
zkgov_check get_eth_id 0x50e420474a6967eaac87813fe6479e98ae8d380fd9b3ae78bc4fedc443d9dec1 --rpc-url $ZKSYNC_RPC_URL
# This will give you the contracts to use in this repo
```
