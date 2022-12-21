// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./HasAdmin.sol";

contract Pausable is HasAdmin {
    event Paused();
    event Unpaused();

    bool public paused;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() public onlyAdmin whenNotPaused {
        paused = true;
        emit Paused();
    }

    function unpause() public onlyAdmin whenPaused {
        paused = false;
        emit Unpaused();
    }
}
