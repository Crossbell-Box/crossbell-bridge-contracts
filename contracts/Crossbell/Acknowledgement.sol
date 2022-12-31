// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./HasOperators.sol";
import "../common/Validator.sol";

contract Acknowledgement is HasOperators {
    // Acknowledge status, once the acknowledgements reach the threshold the 1st
    // time, it can take effect to the system. E.g. confirm a deposit.
    // Acknowledgments after that should not have any effects.
    enum Status {
        NotApproved,
        FirstApproved,
        AlreadyApproved
    }
    // Mapping from channel => boolean
    mapping(bytes32 => bool) public _enabledChannels;
    // Mapping from channel => id => validator => data hash
    mapping(bytes32 => mapping(uint256 => mapping(uint256 => mapping(address => bytes32))))
        public _validatorAck;
    // Mapping from channel => id => data hash => ack count
    mapping(bytes32 => mapping(uint256 => mapping(uint256 => mapping(bytes32 => uint256))))
        public _ackCount;
    // Mapping from channel => id => data hash => ack status
    mapping(bytes32 => mapping(uint256 => mapping(uint256 => mapping(bytes32 => Status))))
        public _ackStatus;

    string public constant DEPOSIT_CHANNEL = "DEPOSIT_CHANNEL";
    string public constant WITHDRAWAL_CHANNEL = "WITHDRAWAL_CHANNEL";
    string public constant VALIDATOR_CHANNEL = "VALIDATOR_CHANNEL";

    Validator public _validator;

    constructor(address validator) {
        addChannel(DEPOSIT_CHANNEL);
        addChannel(WITHDRAWAL_CHANNEL);
        addChannel(VALIDATOR_CHANNEL);
        _validator = Validator(validator);
    }

    function getChannelHash(string memory name) public view returns (bytes32 channel) {
        channel = _getHash(name);
        _requireValidChannel(channel);
    }

    function addChannel(string memory name) public onlyOwner {
        bytes32 channel = _getHash(name);
        _enabledChannels[channel] = true;
    }

    function removeChannel(string memory name) public onlyOwner {
        bytes32 channel = _getHash(name);
        _requireValidChannel(channel);
        delete _enabledChannels[channel];
    }

    function updateValidator(address validator) public onlyOwner {
        _validator = Validator(validator);
    }

    function acknowledge(
        string memory channelName,
        uint256 chainId,
        uint256 id,
        bytes32 hash,
        address validator
    ) public onlyOperator returns (Status) {
        bytes32 channel = getChannelHash(channelName);
        require(
            _validatorAck[channel][chainId][id][validator] == bytes32(0),
            "Acknowledgement: the validator already acknowledged"
        );

        _validatorAck[channel][chainId][id][validator] = hash;
        Status status = _ackStatus[channel][chainId][id][hash];
        uint256 count = _ackCount[channel][chainId][id][hash];

        if (_validator.checkThreshold(count + 1)) {
            if (status == Status.NotApproved) {
                _ackStatus[channel][chainId][id][hash] = Status.FirstApproved;
            } else {
                _ackStatus[channel][chainId][id][hash] = Status.AlreadyApproved;
            }
        }

        _ackCount[channel][chainId][id][hash]++;

        return _ackStatus[channel][chainId][id][hash];
    }

    function hasValidatorAcknowledged(
        string memory channelName,
        uint256 chainId,
        uint256 id,
        address validator
    ) public view returns (bool) {
        bytes32 channel = _getHash(channelName);
        return _validatorAck[channel][chainId][id][validator] != bytes32(0);
    }

    function getAcknowledgementStatus(
        string memory channelName,
        uint256 chainId,
        uint256 id,
        bytes32 hash
    ) public view returns (Status) {
        bytes32 channel = _getHash(channelName);
        return _ackStatus[channel][chainId][id][hash];
    }

    function _getHash(string memory name) internal pure returns (bytes32 hash) {
        hash = keccak256(abi.encode(name));
    }

    function _requireValidChannel(bytes32 channelHash) internal view {
        require(_enabledChannels[channelHash], "Acknowledgement: invalid channel");
    }
}
