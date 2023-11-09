// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

error NotApprovedSign();
abstract contract Relayer{

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes calldata _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(keccak256( abi.encodePacked("\x19Ethereum Signed Message:\n32",_ethSignedMessageHash)), v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
    function _msgSender()
    internal 
    view 
    returns (address) {
        if (msg.data.length >= 65) { /// this is a dumb condition, gonnna addrealayer address mapping
                address signer =  recoverSigner(keccak256(msg.data[:msg.data.length - (65)]), msg.data[msg.data.length - (65):]);
                return signer;
        } else {
            return msg.sender;
        }
    }

    function _msgData() 
    internal 
    pure 
    returns (bytes calldata) {
        if (msg.data.length >= 65) { /// this is a dumb condition, gonnna addrealayer address mapping
            return msg.data[:msg.data.length - (65)];
        } else {
            return msg.data;
        }
    }
}



