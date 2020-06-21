pragma solidity ^0.5.5;

import "../../authority/Owned.sol";
import "./ProxyBase.sol";
import './ContractNames.sol';

/**
 * @title Proxied provides modifiers to limit direct access to KittieFight contracts
 * All public/external function of KittieFight system contracts should be pure/view or
 * have one of this modifiers.
 * @author @pash7ka
 */
contract Proxied is Owned, ContractNames {
    ProxyBase public proxy;

    /**
     * @notice Set/update address of Proxy contract
     */
    function setProxy(ProxyBase _proxy) public onlyOwner {
        proxy = _proxy;
    }

    modifier onlyProxy() {
        _isProxy();
        _;
    }

    modifier onlyContract(string memory name) {
        require(_senderIsContract(name), "Access is only allowed from specific contract");
        _;
    }

    modifier only2Contracts(string memory name1, string memory name2) {
        require(
            _senderIsContract(name1) ||
            _senderIsContract(name2),
             "Access is only allowed from specific contract");
        _;
    }

    modifier only3Contracts(string memory name1, string memory name2, string memory name3) {
        require(
            _senderIsContract(name1) ||
            _senderIsContract(name2) ||
            _senderIsContract(name3),
             "Access is only allowed from specific contract");
        _;
    }

    function _senderIsContract(string memory name) internal view returns(bool){
        require(address(proxy) != address(0), "No Proxy");
        address contractAddress = proxy.getContract(name);
        assert(contractAddress != address(0));    //If this fails, name is probably incorrect
        return (msg.sender == contractAddress);
    }

    function _isProxy() internal view {
        require(address(proxy) != address(0), "No Proxy");
        require(msg.sender == address(proxy), "Only through Proxy");
    }
}
