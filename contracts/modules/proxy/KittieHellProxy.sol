pragma solidity ^0.5.5;

import '../kittieHELL/KittieHELL.sol';
import './ProxyBase.sol';

/**
 * @title KittieHellProxy defines public API of KittieHell contract
 * and redirects calls to KittieHell instance
 */
contract KittieHellProxy is ProxyBase {
    function payForResurrection(uint256 _kittyID) public returns(bool){
        return KittieHELL(addressOfKittieHell()).payForResurrection(_kittyID);
    }
}
