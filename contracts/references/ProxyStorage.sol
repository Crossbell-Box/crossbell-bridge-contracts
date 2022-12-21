// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ProxyStorage
 * @dev Store the address of logic contact that the proxy should forward to.
 */
contract ProxyStorage is Ownable {
    address internal _proxyTo;
}
