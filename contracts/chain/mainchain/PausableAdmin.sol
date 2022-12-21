// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../../references/HasAdmin.sol";
import "../../references/Pausable.sol";

contract PausableAdmin is HasAdmin {
    Pausable public gateway;

    constructor(Pausable _gateway) {
        gateway = _gateway;
    }

    function pauseGateway() external onlyAdmin {
        gateway.pause();
    }

    function unpauseGateway() external onlyAdmin {
        gateway.unpause();
    }
}
