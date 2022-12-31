// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library ECVerify {
    enum SignatureMode {
        EIP712,
        GETH,
        TREZOR
    }

    function recover(bytes32 hash, bytes memory signature) internal pure returns (address _signer) {
        return recover(hash, signature, 0);
    }

    // solium-disable-next-line security/no-assign-params
    function recover(
        bytes32 hash,
        bytes memory signature,
        uint256 index
    ) internal pure returns (address _signer) {
        require(signature.length >= index + 66);

        SignatureMode mode = SignatureMode(uint8(signature[index]));
        bytes32 r;
        bytes32 s;
        uint8 v;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(signature, add(index, 33)))
            s := mload(add(signature, add(index, 65)))
            v := and(255, mload(add(signature, add(index, 66))))
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28);

        if (mode == SignatureMode.GETH) {
            hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        } else if (mode == SignatureMode.TREZOR) {
            hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n\x20", hash));
        }

        return ecrecover(hash, v, r, s);
    }

    function ecverify(
        bytes32 hash,
        bytes memory signature,
        address signer
    ) internal pure returns (bool _valid) {
        return signer == recover(hash, signature);
    }
}
