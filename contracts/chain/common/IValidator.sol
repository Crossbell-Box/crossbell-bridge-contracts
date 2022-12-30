// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IValidator {
    event ValidatorAdded(address indexed _validator);
    event ValidatorRemoved(address indexed _validator);
    event RequirementChanged(uint256 indexed _requirement, uint256 indexed _previousRequired);

    function isValidator(address _addr) external view returns (bool);

    function getValidators() external view returns (address[] memory _validators);

    function checkThreshold(uint256 _voteCount) external view returns (bool);
}
