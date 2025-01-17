// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

// src/interfaces/IProtocolUpgradeHandler.sol

/// @author Matter Labs
/// @custom:security-contact security@matterlabs.dev
interface IProtocolUpgradeHandler {
    /// @dev This enumeration includes the following states:
    /// @param None Default state, indicating the upgrade has not been set.
    /// @param LegalVetoPeriod The upgrade passed L2 voting process but it is waiting for the legal veto period.
    /// @param Waiting The upgrade passed Legal Veto period but it is waiting for the approval from guardians or Security Council.
    /// @param ExecutionPending The upgrade proposal is waiting for the delay period before being ready for execution.
    /// @param Ready The upgrade proposal is ready to be executed.
    /// @param Expired The upgrade proposal was expired.
    /// @param Done The upgrade has been successfully executed.
    enum UpgradeState {
        None,
        LegalVetoPeriod,
        Waiting,
        ExecutionPending,
        Ready,
        Expired,
        Done
    }

    /// @dev Represents the status of an upgrade process, including the creation timestamp and actions made by guardians and Security Council.
    /// @param creationTimestamp The timestamp (in seconds) when the upgrade state was created.
    /// @param securityCouncilApprovalTimestamp The timestamp (in seconds) when Security Council approved the upgrade.
    /// @param guardiansApproval Indicates whether the upgrade has been approved by the guardians.
    /// @param guardiansExtendedLegalVeto Indicates whether guardians extended the legal veto period.
    /// @param executed Indicates whether the proposal is executed or not.
    struct UpgradeStatus {
        uint48 creationTimestamp;
        uint48 securityCouncilApprovalTimestamp;
        bool guardiansApproval;
        bool guardiansExtendedLegalVeto;
        bool executed;
    }

    /// @dev Represents a call to be made during an upgrade.
    /// @param target The address to which the call will be made.
    /// @param value The amount of Ether (in wei) to be sent along with the call.
    /// @param data The calldata to be executed on the `target` address.
    struct Call {
        address target;
        uint256 value;
        bytes data;
    }

    /// @dev Defines the structure of an upgrade that is executed by Protocol Upgrade Handler.
    /// @param executor The L1 address that is authorized to perform the upgrade execution (if address(0) then anyone).
    /// @param calls An array of `Call` structs, each representing a call to be made during the upgrade execution.
    /// @param salt A bytes32 value used for creating unique upgrade proposal hashes.
    struct UpgradeProposal {
        Call[] calls;
        address executor;
        bytes32 salt;
    }

    /// @dev This enumeration includes the following states:
    /// @param None Default state, indicating the freeze has not been happening in this upgrade cycle.
    /// @param Soft The protocol is/was frozen for the short time.
    /// @param Hard The protocol is/was frozen for the long time.
    /// @param AfterSoftFreeze The protocol was soft frozen, it can be hard frozen in this upgrade cycle.
    /// @param AfterHardFreeze The protocol was hard frozen, but now it can't be frozen until the upgrade.
    enum FreezeStatus {
        None,
        Soft,
        Hard,
        AfterSoftFreeze,
        AfterHardFreeze
    }

    function startUpgrade(
        uint256 _l2BatchNumber,
        uint256 _l2MessageIndex,
        uint16 _l2TxNumberInBatch,
        bytes32[] calldata _proof,
        UpgradeProposal calldata _proposal
    ) external;

    function extendLegalVeto(bytes32 _id) external;

    function approveUpgradeSecurityCouncil(bytes32 _id) external;

    function approveUpgradeGuardians(bytes32 _id) external;

    function execute(UpgradeProposal calldata _proposal) external payable;

    function executeEmergencyUpgrade(
        UpgradeProposal calldata _proposal
    ) external payable;

    function softFreeze() external;

    function hardFreeze() external;

    function reinforceFreeze() external;

    function unfreeze() external;

    function reinforceFreezeOneChain(uint256 _chainId) external;

    function reinforceUnfreeze() external;

    function reinforceUnfreezeOneChain(uint256 _chainId) external;

    function upgradeState(bytes32 _id) external view returns (UpgradeState);

    function updateSecurityCouncil(address _newSecurityCouncil) external;

    function updateGuardians(address _newGuardians) external;

    function updateEmergencyUpgradeBoard(
        address _newEmergencyUpgradeBoard
    ) external;

    /// @notice Emitted when the security council address is changed.
    event ChangeSecurityCouncil(
        address indexed _securityCouncilBefore,
        address indexed _securityCouncilAfter
    );

    /// @notice Emitted when the guardians address is changed.
    event ChangeGuardians(
        address indexed _guardiansBefore,
        address indexed _guardiansAfter
    );

    /// @notice Emitted when the emergency upgrade board address is changed.
    event ChangeEmergencyUpgradeBoard(
        address indexed _emergencyUpgradeBoardBefore,
        address indexed _emergencyUpgradeBoardAfter
    );

    /// @notice Emitted when upgrade process on L1 is started.
    event UpgradeStarted(bytes32 indexed _id, UpgradeProposal _proposal);

    /// @notice Emitted when the legal veto period is extended.
    event UpgradeLegalVetoExtended(bytes32 indexed _id);

    /// @notice Emitted when Security Council approved the upgrade.
    event UpgradeApprovedBySecurityCouncil(bytes32 indexed _id);

    /// @notice Emitted when Guardians approved the upgrade.
    event UpgradeApprovedByGuardians(bytes32 indexed _id);

    /// @notice Emitted when the upgrade is executed.
    event UpgradeExecuted(bytes32 indexed _id);

    /// @notice Emitted when the emergency upgrade is executed.
    event EmergencyUpgradeExecuted(bytes32 indexed _id);

    /// @notice Emitted when the protocol became soft frozen.
    event SoftFreeze(uint256 _protocolFrozenUntil);

    /// @notice Emitted when the protocol became hard frozen.
    event HardFreeze(uint256 _protocolFrozenUntil);

    /// @notice Emitted when someone makes an attempt to freeze the protocol when it is frozen already.
    event ReinforceFreeze();

    /// @notice Emitted when the protocol became active after the soft/hard freeze.
    event Unfreeze();

    /// @notice Emitted when someone makes an attempt to freeze the specific chain when the protocol is frozen already.
    event ReinforceFreezeOneChain(uint256 _chainId);

    /// @notice Emitted when someone makes an attempt to unfreeze the protocol when it is unfrozen already.
    event ReinforceUnfreeze();

    /// @notice Emitted when someone makes an attempt to unfreeze the specific chain when the protocol is unfrozen already.
    event ReinforceUnfreezeOneChain(uint256 _chainId);
}

// src/UpgradeChecker.sol

contract UpgradeCheckerFlat {
    function execute(
        IProtocolUpgradeHandler.UpgradeProposal calldata _proposal
    ) external payable {}

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
