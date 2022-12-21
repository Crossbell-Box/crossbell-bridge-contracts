// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract HasAdmin {
    event AdminChanged(address indexed _oldAdmin, address indexed _newAdmin);
    event AdminRemoved(address indexed _oldAdmin);

    address public admin;

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    constructor() {
        admin = msg.sender;
        emit AdminChanged(address(0), admin);
    }

    function changeAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0));
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }

    function removeAdmin() external onlyAdmin {
        emit AdminRemoved(admin);
        admin = address(0);
    }
}
