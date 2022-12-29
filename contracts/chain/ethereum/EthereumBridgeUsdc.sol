// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../mainchain/MainchainBridge.sol";

contract EthereumBridgeUsdc is MainchainBridge {
    // as there are different token decimals on different chains, so the amount need to be transformed
    function _transformAmount(
        uint256 amount
    ) internal pure override returns (uint256 transformedAmount) {
        transformedAmount = amount * Constants.SCALE;
    }
}
