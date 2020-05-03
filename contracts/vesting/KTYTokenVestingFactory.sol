pragma solidity ^0.5.5;

import './zeppelin/Ownable.sol';
import "../interfaces/ERC20Standard.sol";
import "./KTYTokenVesting.sol";

/**
 * @title KTYTokenVestingFactory
 * @notice Provides single source of deploy events for vesting contracts
 */
contract KTYTokenVestingFactory is Ownable {
    ERC20Standard public token;

    event VestingWalletCreated(address indexed beneficiary, address wallet, uint256 amount);

    constructor(ERC20Standard _token) public{
        token = _token;
    }

    /**
     * @param beneficiary Who will receive tokens
     * @param amount How many tokens should me minted
     * @param vestingStart When vesting should start (beneficieary can not recieve tokens untill this time)
     * @param vestingEnd When vesting should end (beneficieary can recieve all tokens after this time)
     * @param revocable If owner can revoke tokens (only until they are vested)
     */    
    function createVestingWallet(address beneficiary, uint256 amount, uint256 vestingStart, uint256 vestingEnd, bool revocable) onlyOwner public {
        require(vestingEnd >= vestingStart, "Can not end before start");
        uint256 duration = vestingEnd - vestingStart;
        KTYTokenVesting wallet = new KTYTokenVesting(beneficiary, vestingStart, 0, duration, revocable);
        emit VestingWalletCreated(beneficiary, address(wallet), amount);

        token.transferFrom(msg.sender, address(wallet), amount);
        wallet.transferOwnership(msg.sender);   //transfer ability to revoke tokens to the creator
    }

}
