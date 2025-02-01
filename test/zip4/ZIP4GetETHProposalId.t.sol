// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {IProtocolUpgradeHandler} from "src/interfaces/IProtocolUpgradeHandler.sol";

contract ZIP4Test {
    address ZERO = address(0);

    // Update the calls with the calls the proposal is going to make
    bytes32 salt = 0x0000000000000000000000000000000000000000000000000000000000000000;

    // Fill me in with the data!
    // cast decode-calldata "execute(((address,uint256,bytes)[],address,bytes32))"  0x
    // The outputs go here!
    IProtocolUpgradeHandler.Call callOne = IProtocolUpgradeHandler.Call({
        target: 0x5D8ba173Dc6C3c90C8f7C04C9288BeF5FDbAd06E,
        value: 0,
        data: hex"f34d18680000000000000000000000000000000000000000000000000000000000002a30"
    });
    IProtocolUpgradeHandler.Call[] calls;

    constructor() {
        calls.push(callOne);
    }

    function getHash() public view returns (bytes32) {
        IProtocolUpgradeHandler.UpgradeProposal memory upgradeProposal =
            IProtocolUpgradeHandler.UpgradeProposal({calls: calls, salt: salt, executor: ZERO});
        bytes32 id = keccak256(abi.encode(upgradeProposal));
        return id;
    }
}

contract BaseGetETHHashProposalIdTest is Test {
    ZIP4Test zip;

    function setUp() public {
        zip = new ZIP4Test();
    }

    function testZip4EthProposalId() public view {
        bytes32 hash = zip.getHash();
        console.logBytes32(hash);
    }
}
