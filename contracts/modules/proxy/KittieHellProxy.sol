pragma solidity ^0.5.5;

import '../../CronJob.sol';
import '../kittieHELL/KittieHELL.sol';
import './ProxyBase.sol';

/**
 * @title KittieHellProxy defines public API of KittieHell contract
 * and redirects calls to KittieHell instance
 */
contract KittieHellProxy is ProxyBase {
    function acquireKitty(uint256 _kittyID, address owner) public payable returns(bool){
        return KittieHELL(addressOfKittieHell()).acquireKitty(_kittyID, owner);
    }

    function releaseKitty(uint256 _kittyID) public returns(bool){
        return CronJob(addressOfCronJob()).releaseKitty(_kittyID);
    }

    function payForResurrection(uint256 _kittyID) public returns(bool){
        return KittieHELL(addressOfKittieHell()).payForResurrection(_kittyID);
    }
}
