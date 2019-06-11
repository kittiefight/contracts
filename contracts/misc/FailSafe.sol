pragma solidity ^0.5.5;

import "./../interfaces/ERC20Basic.sol";
import "./../authority/Owned.sol";

/**
 * @title FailSafe
 * @dev this is a fail safe contract to unlock tokens on ether from a contract
 */
contract FailSafe is Owned {

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);

    /**
     * @notice This method can be used by the controller to extract
     * sent tokens to this contract.
     * @param _token The address of the token contract that you want to recover
     * set to 0 in case you want to extract ether.
     */
    function claimTokens(address _token) public onlyOwner {
        // Transfer ether
        if (_token == address(0)) {
            owner.transfer(address(this).balance);
            return;
        }

        ERC20Basic token = ERC20Basic(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);
        emit ClaimedTokens(_token, owner, balance);
    }
}
