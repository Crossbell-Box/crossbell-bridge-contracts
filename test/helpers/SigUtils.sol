// SPDX-License-Identifier: MIT
// solhint-disable comprehensive-interface
pragma solidity 0.8.16;

contract SigUtils {
    struct Permit {
        address owner;
        address spender;
        uint256 value;
        uint256 nonce;
        uint256 deadline;
    }

    // solhint-disable-next-line var-name-mixedcase,private-vars-leading-underscore
    bytes32 internal DOMAIN_SEPARATOR;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    constructor(bytes32 domainSeparator) {
        DOMAIN_SEPARATOR = domainSeparator;
    }

    // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getTypedDataHash(Permit memory permit) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, _getStructHash(permit)));
    }

    // computes the hash of a permit
    function _getStructHash(Permit memory permit) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PERMIT_TYPEHASH,
                    permit.owner,
                    permit.spender,
                    permit.value,
                    permit.nonce,
                    permit.deadline
                )
            );
    }
}
