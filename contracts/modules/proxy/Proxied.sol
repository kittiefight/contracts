pragma solidity ^0.5.5;

import "../../authority/Owned.sol";
import "../../KFProxy.sol";
import './ContractNames.sol';

/**
 * @title Proxied provides modifiers to limit direct access to KittieFight contracts
 * All public/external function of KittieFight system contracts should be pure/view or
 * have one of this modifiers.
 * @author @pash7ka
 */
contract Proxied is Owned, ContractNames {
    KFProxy public proxy;

    /**
     * @notice Set/update address of Proxy contract
     */
    function setProxy(KFProxy _proxy) public onlyOwner {
        proxy = _proxy;
    }

    modifier onlyProxy() {
        _isProxy();
        _;
    }

    modifier onlyContract(string memory name) {
        _isContractAuthorized(name);
        _;
    }

    function _isContractAuthorized(string memory name) internal view {
        require(address(proxy) != address(0), "No Proxy");
        address allowedSender = proxy.getContract(name);
        assert(allowedSender != address(0));    //If this fails, name is probably incorrect
        require(msg.sender == allowedSender, "Access is only allowed from specific contract");
    }

    function _isProxy() internal view {
        require(address(proxy) != address(0), "No Proxy");
        require(msg.sender == address(proxy), "Only through Proxy");
    }
}
