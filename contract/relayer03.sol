// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
*   this version uses nounce
*   and address mapping
*   this version is even better than version 04
*/

error NotApprovedSign();
error NotCorrectNounce(uint256, uint256);

abstract contract Relayer{
    mapping (address => uint256) public _isRelayer;
    mapping (address => uint256) public _userNounce; ///32 bit nounce

    function _AddSelfAsRelayer()
    public{
        _isRelayer[msg.sender] = 1;
    }

    function _RemoveSelfAsRelayer()
    public{
        _isRelayer[msg.sender] = 0;
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

    // function splitNounce(
    //     bytes memory nounce
    // ) public pure returns (uint256 nounceExtracted) {
    //     if(nounce.length != 32){
    //         revert NotApprovedSign();
    //     }

    //     assembly {
    //         nounceExtracted := mload(add(nounce, 32))
    //     }
    // }
    
    function _msgSender() /// !!!!! should only be called once
    internal  
    returns (address) {
        if (_isRelayer[msg.sender]==1) {
            address signer =  recoverSigner(keccak256(msg.data[:msg.data.length - (97)]), msg.data[msg.data.length - (65):]);
            uint256 nounceExtracted;
            bytes32 nounce = bytes32(msg.data[msg.data.length - (97):msg.data.length - (65)]);
            assembly {
                nounceExtracted := mload(add(nounce, 32))
            }
            if(nounceExtracted != ++_userNounce[signer]){
                revert NotCorrectNounce(_userNounce[signer]+1, nounceExtracted);
            }

            return signer;
        } else {
            return msg.sender;
        }
    }

    function _msgData() 
    internal 
    view 
    returns (bytes calldata) {
        if (_isRelayer[msg.sender]==1) {
            return msg.data[:msg.data.length - (97)];
        } else {
            return msg.data;
        }
    }
}



