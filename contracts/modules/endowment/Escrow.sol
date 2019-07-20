pragma solidity ^0.5.5;

/**
 * @title Escrow Contract
 * @dev Owns the tokens
 * Not marked with onlyProxy() because it will be called after deploying new Escrow contract
 * and proxy will point to the new one.
 * @ author
 */

//import "../proxy/Proxied.sol";
//import "../proxy/ContractNames.sol";
import "../../authority/Owned.sol";
import "../../interfaces/ERC20Standard.sol";

contract Escrow is Owned{

    ERC20Standard public kittieFightToken;

    /**
   * @dev Initialize contracts used
   * @dev Can be called only by the owner of this contract
   */
    function initialize(address ktyAddress) external onlyOwner {
        kittieFightToken = ERC20Standard(address(ktyAddress));
    }

    function () external payable {}

    function transferETH(address payable _to, uint256 _eth_amount) public onlyOwner returns(bool){
        _to.transfer(_eth_amount);
        return true;
    }

    function transferKTY(address _to, uint256 _kty_amount) public onlyOwner returns(bool){
        kittieFightToken.transfer(_to, _kty_amount);
        return true;
    }





}