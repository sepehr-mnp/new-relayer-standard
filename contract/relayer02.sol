// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
/// in this standard we have address mapping

error NotApprovedSign();
abstract contract Relayer{
    mapping (address => uint) public isRelayer;

    function _AddSelfAsRelayer()
    public{
        isRelayer[msg.sender] = 1;
    }

    function _RemoveSelfAsRelayer()
    public{
        isRelayer[msg.sender] = 0;
    }

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
        if (isRelayer[msg.sender]==1) {
                address signer =  recoverSigner(keccak256(msg.data[:msg.data.length - (65)]), msg.data[msg.data.length - (65):]);
                return signer;
        } else {
            return msg.sender;
        }
    }

    function _msgData() 
    internal 
    view 
    returns (bytes calldata) {
        if (isRelayer[msg.sender]==1) {
            return msg.data[:msg.data.length - (65)];
        } else {
            return msg.data;
        }
    }
}



