// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {IProtocolUpgradeHandler} from "src/interfaces/IProtocolUpgradeHandler.sol";

contract ZIPXTest {
    address ZERO = address(0);

    // Update the calls with the calls the proposal is going to make
    bytes32 salt = 0x0000000000000000000000000000000000000000000000000000000000000000;

    // Fill me in with the data!
    // cast calldata-decode ""
    IProtocolUpgradeHandler.Call callOne = IProtocolUpgradeHandler.Call({
        target: ZERO,
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
    ZIPXTest zip;

    function setUp() public {
        zip = new ZIPXTest();
    }

    function testZipXEthProposalId() public view {
        bytes32 hash = zip.getHash();
        console.logBytes32(hash);
    }
}
