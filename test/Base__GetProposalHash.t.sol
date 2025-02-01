// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {GetProposalHash} from "src/GetProposalHash.sol";

contract GetProposalHashTest is Test {
    GetProposalHash getProposalHash;
    address[] targets;
    uint256[] values;
    bytes[] calldatas;
    bytes32 descriptionHash;

    function setUp() public {
        getProposalHash = new GetProposalHash();
    }
}
