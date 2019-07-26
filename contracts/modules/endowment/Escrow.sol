pragma solidity ^0.5.5;

/**
 * @title Escrow Contract
 * @dev Tokens are stored here
 * @ author
 */
import "../../authority/Owned.sol";
import "../../interfaces/ERC20Standard.sol";

contract Escrow is Owned {

    ERC20Standard public kittieFightToken;

    event EthTransfered(address to, uint256 amount);
    event KtyTransfered(address to, uint256 amount);

    /**
    * @dev Initialize contracts used
    */
    function initialize(ERC20Standard _kittieFightToken) external onlyOwner {
        //kittieFightToken = ERC20Standard(address(ktyAddress));
        kittieFightToken = _kittieFightToken;
    }

    function () external payable {}

    function transferETH(address payable _to, uint256 _eth_amount) public onlyOwner returns(bool){
        _to.transfer(_eth_amount);
        emit EthTransfered(_to, _eth_amount);
        return true;
    }

    function transferKTY(address _to, uint256 _kty_amount) public onlyOwner returns(bool){
        
        kittieFightToken.transfer(_to, _kty_amount);
        emit EthTransfered(_to, _kty_amount);
        return true;
    }

    function getBalanceKTY() public view returns (uint256){
        return kittieFightToken.balanceOf(address(this));
    }

    function getBalanceETH() public view returns (uint256){
        return  address(this).balance;
    }

    function getKTYaddress() public view returns (address){
        return  address(kittieFightToken);
    }

}