// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
*   this version uses nounce
*   and address mapping
*   and gas left mapping
*   the only scenario that this can go wrong is that somehow there is a logic in the contract
*   that changes the way that our function works completely in a block. but this bug is somehow
*   in the whole foundation of relayers because when you give your transactions to a relayer, it has the
*   ability to send it whenever it wants and they can send it even after that changing in the base of function
*   so contracts process flow should not depend on the external state somehow that it lets the second transaction that
*   uses this signature to have it's _msgSender() called after having less gas than the last time that it was computed on this block 
*/

error NotApprovedSign();
error NotCorrectNounce(uint256, uint256);

abstract contract Relayer{
    struct UserNounce{
        uint256 nounce;
        bytes32 hashOfTransaction;
    }

    struct UserGas{
        uint144 gas;
        address addressOfUser;
    }
    mapping (address => uint256) public _isRelayer;
    mapping (address => UserNounce) public _userNounce; ///32 bit nounce
    mapping (bytes32 => UserGas) private _gasLeft;

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

    
    function _msgSender()
    internal  
    returns (address signer) {
        if (_isRelayer[msg.sender]==1) {
            bytes32 hashOfTransactionGotten = keccak256(abi.encode(tx.gasprice, block.number ,msg.data[msg.data.length - (65):]));
            if(_gasLeft[hashOfTransactionGotten].gas-500 <= gasleft()){ 
                signer =  recoverSigner(keccak256(msg.data[:msg.data.length - (97)]), msg.data[msg.data.length - (65):]);
                uint256 nounceExtracted;
                bytes32 nounce = bytes32(msg.data[msg.data.length - (97):msg.data.length - (65)]);
                assembly {
                    nounceExtracted := mload(add(nounce, 32))
                }
                if(nounceExtracted != ++_userNounce[signer].nounce){
                    revert NotCorrectNounce(_userNounce[signer].nounce+1, nounceExtracted);
                }

                
                _userNounce[signer].hashOfTransaction = hashOfTransactionGotten;
                _gasLeft[hashOfTransactionGotten].addressOfUser= signer;
            }else{
                signer = _gasLeft[hashOfTransactionGotten].addressOfUser;
            }
            _gasLeft[hashOfTransactionGotten].gas = uint144(gasleft());
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



