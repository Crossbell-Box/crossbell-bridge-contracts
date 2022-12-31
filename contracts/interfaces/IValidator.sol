// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IValidator {
    event ValidatorAdded(address indexed validator);
    event ValidatorRemoved(address indexed validator);
    event RequirementChanged(uint256 indexed requirement, uint256 indexed previousRequired);

    function addValidators(address[] calldata validators) external;

    function removeValidators(address[] calldata validators) external;

    function changeRequiredNumber(uint256 newRequiredNumber) external;

    function getValidators() external view returns (address[] memory validators);

    function getRequiredNumber() external view returns (uint256);

    function checkThreshold(uint256 voteCount) external view returns (bool);

    function isValidator(address addr) external view returns (bool);
}
