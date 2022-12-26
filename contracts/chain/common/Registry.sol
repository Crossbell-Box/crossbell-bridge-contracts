// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Registry is Ownable {
    event ContractAddressUpdated(
        string indexed _name,
        bytes32 indexed _code,
        address indexed _newAddress
    );

    string public constant GATEWAY = "GATEWAY";
    string public constant TOKEN = "TOKEN";
    string public constant VALIDATOR = "VALIDATOR";
    string public constant ACKNOWLEDGEMENT = "ACKNOWLEDGEMENT";

    mapping(bytes32 => address) public contractAddresses;

    function getContract(string calldata _name) external view returns (address _address) {
        bytes32 _code = getCode(_name);
        _address = contractAddresses[_code];
        require(_address != address(0));
    }

    function updateContract(string calldata _name, address _newAddress) external onlyOwner {
        bytes32 _code = getCode(_name);
        contractAddresses[_code] = _newAddress;

        emit ContractAddressUpdated(_name, _code, _newAddress);
    }

    function getCode(string memory _name) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_name));
    }
}
