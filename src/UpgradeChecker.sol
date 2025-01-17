// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {IProtocolUpgradeHandler} from "./interfaces/IProtocolUpgradeHandler.sol";

contract GetHashOfZkSyncProposal {
    // Update the calls with the calls the proposal is going to make

    bytes32 salt =
        0x646563656e7472616c697a6174696f6e206973206e6f74206f7074696f6e616c;
    IProtocolUpgradeHandler.Call callOne =
        IProtocolUpgradeHandler.Call({
            target: 0xD7f9f54194C633F36CCD5F3da84ad4a1c38cB2cB,
            value: 0,
            data: hex"79ba5097"
        });
    IProtocolUpgradeHandler.Call callTwo =
        IProtocolUpgradeHandler.Call({
            target: 0x303a465B659cBB0ab36eE643eA362c509EEb5213,
            value: 0,
            data: hex"79ba5097"
        });
    IProtocolUpgradeHandler.Call callThree =
        IProtocolUpgradeHandler.Call({
            target: 0xc2eE6b6af7d616f6e27ce7F4A451Aedc2b0F5f5C,
            value: 0,
            data: hex"79ba5097"
        });
    IProtocolUpgradeHandler.Call callFour =
        IProtocolUpgradeHandler.Call({
            target: 0x5D8ba173Dc6C3c90C8f7C04C9288BeF5FDbAd06E,
            value: 0,
            data: hex"79ba5097"
        });
    IProtocolUpgradeHandler.Call[] calls;

    constructor() {
        calls.push(callOne);
        calls.push(callTwo);
        calls.push(callThree);
        calls.push(callFour);
    }

    function getHash() public view returns (bytes32) {
        IProtocolUpgradeHandler.UpgradeProposal
            memory upgradeProposal = IProtocolUpgradeHandler.UpgradeProposal({
                calls: calls,
                salt: salt,
                executor: 0xdEFd1eDEE3E8c5965216bd59C866f7f5307C9b29
            });
        bytes32 id = keccak256(abi.encode(upgradeProposal));
        return id;
    }
}
