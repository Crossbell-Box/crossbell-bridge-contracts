// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../common/Validator.sol";
import "./Acknowledgement.sol";
import "../../references/Constants.sol";

/**
 * @title Validator
 * @dev Simple validator contract
 */
contract SidechainValidator is Validator {
    Acknowledgement public acknowledgement;

    modifier onlyValidator() {
        require(_isValidator(msg.sender));
        _;
    }

    constructor(
        address _acknowledgement,
        address[] memory _validators,
        uint256 _required
    ) Validator(_validators, _required) {
        acknowledgement = Acknowledgement(_acknowledgement);
    }

    function addValidator(uint256 _id, address _validator) external onlyValidator {
        bytes32 _hash = keccak256(abi.encode("addValidator", _validator));

        Acknowledgement.Status _status = acknowledgement.acknowledge(
            _getAckChannel(),
            Constants.ETHEREUM_CHAIN_ID,
            _id,
            _hash,
            msg.sender
        );
        if (_status == Acknowledgement.Status.FirstApproved) {
            _addValidator(_id, _validator);
        }
    }

    function removeValidator(uint256 _id, address _validator) external onlyValidator {
        require(_isValidator(_validator));

        bytes32 _hash = keccak256(abi.encode("removeValidator", _validator));

        Acknowledgement.Status _status = acknowledgement.acknowledge(
            _getAckChannel(),
            Constants.ETHEREUM_CHAIN_ID,
            _id,
            _hash,
            msg.sender
        );
        if (_status == Acknowledgement.Status.FirstApproved) {
            _removeValidator(_id, _validator);
        }
    }

    function changeRequirement(uint256 _id, uint256 _required) external onlyValidator {
        bytes32 _hash = keccak256(abi.encode("changeRequirement", _required));

        Acknowledgement.Status _status = acknowledgement.acknowledge(
            _getAckChannel(),
            Constants.ETHEREUM_CHAIN_ID,
            _id,
            _hash,
            msg.sender
        );
        if (_status == Acknowledgement.Status.FirstApproved) {
            _changeRequirement(_id, _required);
        }
    }

    function _getAckChannel() internal view returns (string memory) {
        return acknowledgement.VALIDATOR_CHANNEL();
    }
}
