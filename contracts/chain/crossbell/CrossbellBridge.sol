// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../sidechain/SidechainBridge.sol";

contract CrossbellBridge is SidechainBridge {
    function _transformAmount(
        uint256 _chainId,
        uint256 _amount
    ) internal pure override returns (uint256 _transformedAmount) {
        if (_chainId == Constants.ETHEREUM_CHAIN_ID) {
            _transformedAmount = _amount / Constants.SCALE;
        } else if (_chainId == Constants.POLYGON_CHAIN_ID) {
            _transformedAmount = _amount / Constants.SCALE;
        } else if (_chainId == Constants.BSC_CHAIN_ID) {
            _transformedAmount = _amount;
        } else {
            revert("UnsupportedChainID");
        }
    }
}
