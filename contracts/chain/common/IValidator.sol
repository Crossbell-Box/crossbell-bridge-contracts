// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IValidator {
    event ValidatorAdded(uint256 indexed _id, address indexed _validator);
    event ValidatorRemoved(uint256 indexed _id, address indexed _validator);
    event RequirementChanged(
        uint256 indexed _id,
        uint256 indexed _requirement,
        uint256 indexed _previousRequired
    );

    function isValidator(address _addr) external view returns (bool);

    function getValidators() external view returns (address[] memory _validators);

    function checkThreshold(uint256 _voteCount) external view returns (bool);
}
