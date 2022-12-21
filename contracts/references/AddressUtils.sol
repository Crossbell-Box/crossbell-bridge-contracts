// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library AddressUtils {
    function isContract(
        address _address
    ) internal view returns (bool _correct) {
        uint256 _size;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            _size := extcodesize(_address)
        }
        return _size > 0;
    }
}
