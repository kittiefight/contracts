pragma solidity ^0.5.5;

import './zeppelin/HasNoEther.sol';
import './zeppelin/HasNoContracts.sol';
import './zeppelin/TokenVesting.sol';

/**
 * @title KTYTokenVesting
 * @dev Extends TokenVesting contract to allow reclaim ether and contracts, if transfered to this by mistake.
 */
contract KTYTokenVesting is TokenVesting, HasNoEther, HasNoContracts {

    /**
     * @dev Call consturctor of TokenVesting with exactly same parameters
     */
    constructor(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) 
        TokenVesting(   _beneficiary,         _start,         _cliff,         _duration,      _revocable) 
        public {}

}
