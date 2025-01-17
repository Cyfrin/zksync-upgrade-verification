// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract GetProposalHash {
    function hashDescription(
        string memory description
    ) public pure returns (bytes32) {
        return keccak256(bytes(description));
    }

    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public pure virtual returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(targets, values, calldatas, descriptionHash)
                )
            );
    }
}
