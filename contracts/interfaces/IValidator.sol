// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/**
 * @title IValidator
 * @notice This is the interface for the validator contract.
 * You'll find all the events and external functions.
 */
interface IValidator {
    /**
     * @dev Emitted when a new validator is added.
     * @param validator The validator address to add.
     */
    event ValidatorAdded(address indexed validator);

    /**
     * @dev Emitted when a validator is removed.
     * @param validator The validator address to remove.
     */
    event ValidatorRemoved(address indexed validator);

    /**
     * @dev Emitted when a new required number is set.
     * @param requirement The new required number to set.
     * @param previousRequired The previous required number.
     */
    event RequirementChanged(uint256 indexed requirement, uint256 indexed previousRequired);

    /**
     * @notice Adds new validators. This function can only be called by the owner of validator contract.
     * Note that this reverts if new validators to add are already validators.
     * @param validators New validator addresses to add
     */
    function addValidators(address[] calldata validators) external;

    /**
     * @notice Removes exist validators. This function can only be called by the owner of validator contract.
     * Note that this reverts if validators to remove are not validators.
     * @param validators Validator addresses to remove
     */
    function removeValidators(address[] calldata validators) external;

    /**
     * @notice Change the required number of validators.
     * Requirements::
     *  1. the caller is owner of validator contract.
     *  2. new required number > validators length.
     *  3. new required number is zero.
     * @param newRequiredNumber New required number to set.
     */
    function changeRequiredNumber(uint256 newRequiredNumber) external;

    /**
     * @notice Returns whether an address is validator or not.
     * @param addr Address to query.
     */
    function isValidator(address addr) external view returns (bool);

    /**
     * @notice Returns all the validators.
     */
    function getValidators() external view returns (address[] memory validators);

    /**
     * @notice Returns current required number.
     */
    function getRequiredNumber() external view returns (uint256);

    /**
     * @notice Checks whether the `voteCount` passes the threshold.
     */
    function checkThreshold(uint256 voteCount) external view returns (bool);
}
