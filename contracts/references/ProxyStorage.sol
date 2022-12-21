// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./HasAdmin.sol";

/**
 * @title ProxyStorage
 * @dev Store the address of logic contact that the proxy should forward to.
 */
contract ProxyStorage is HasAdmin {
    address internal _proxyTo;
}
