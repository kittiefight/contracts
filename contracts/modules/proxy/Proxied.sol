pragma solidity ^0.5.5;

import "../../authority/Owned.sol";
import "../../Proxy.sol";
import './ContractNames.sol';

/**
 * @title Proxied provides modifiers to limit direct access to KittieFight contracts
 * All public/external function of KittieFight system contracts should be pure/view or
 * have one of this modifiers.
 * @author @pash7ka
 */
contract Proxied is Owned, ContractNames {
    Proxy public proxy;

    /**
     * @notice Set/update address of Proxy contract
     */
    function setProxy(Proxy _proxy) public onlyOwner {
        proxy = _proxy;
    }

    modifier onlyProxy(){
        require(address(proxy) != address(0), "Set Proxy address first");
        require(msg.sender == address(proxy), "Access is only allowed through Proxy");
        _;
    }

    modifier onlyContract(string memory name){
        require(address(proxy) != address(0), "Set Proxy address first");
        address allowedSender = proxy.getContract(name);
        assert(allowedSender != address(0));    //If this fails, name is probably incorrect
        require(msg.sender == allowedSender, "Access is only allowed from specific contract");
        _;
    }

}
