// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../references/Pausable.sol";

contract PausableAdmin is Ownable {
    Pausable public gateway;

    constructor(Pausable _gateway) {
        gateway = _gateway;
    }

    function pauseGateway() external onlyOwner {
        gateway.pause();
    }

    function unpauseGateway() external onlyOwner {
        gateway.unpause();
    }
}
