pragma solidity ^0.5.5;

/**
 * @title Escrow Contract
 * @dev Owns the tokens
 * Not marked with onlyProxy() because it will be called after deploying new Escrow contract
 * and proxy will point to the new one.
 * @author @vikrammandal
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

    /**
    * @dev upgrade Escrow contract
    * where to place this function??
     * /
    function upgradeEscrow() external onlyOwner {

        address newEscrow = proxy.getContract('Escrow');
        newEscrow.transfer(address(this).balance);
        uint256 ktyBalance = kittieFightToken.balance(address(this));
        kittieFightToken.transfer(newEscrow, ktyBalance);

    }*/


}