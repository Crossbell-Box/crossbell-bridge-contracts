// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../../references/Proxy.sol";
import "../common/Validator.sol";
import "../common/Registry.sol";
import "./MainchainGatewayStorage.sol";

contract MainchainGatewayProxy is Proxy, MainchainGatewayStorage {
    constructor(address _proxyTo, address _registry) Proxy(_proxyTo) {
        registry = Registry(_registry);
    }
}