pragma solidity 0.4.21;

import "../interfaces/ERC20Basic.sol";
import "../controllers/Owned.sol";

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
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }

        ERC20Basic token = ERC20Basic(_token);
        uint balance = token.balanceOf(this);
        token.transfer(owner, balance);
        emit ClaimedTokens(_token, owner, balance);
    }
}
