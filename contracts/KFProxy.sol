pragma solidity ^0.5.5;

import "./libs/zos-lib/Initializable.sol";
import "./modules/proxy/ProxyBase.sol";

/**
 * @title Proxy contract is a main entry point for KittyFight contract system
 * @author @pash7ka
 */
contract KFProxy is
    Initializable,          //Allows to use ZeppelinOS Proxy
    ProxyBase
{

    /**
     * This function should be run instead of constructor
     * See https://docs.zeppelinos.org/docs/pattern.html#the-constructor-caveat
     */
    function initialize() initializer public {
        //TODO: Initialize contract addressses here or in separate function
    }

    /**
     * Make default function non-payable
     */
    function () external {}

    /**
     * @dev This function forwards a payload and ether to specified contract
     * @param contractName Name of the contract to worward a message to. Uses ContractManager to get address of the contract
     * @param payload Data to send to the target contract. It should contain method signature and arguments packed.
     * It's possible to use https://web3js.readthedocs.io/en/1.0/web3-eth-abi.html#encodefunctioncall to generate this
     */
    function execute(string calldata contractName, bytes calldata payload) external payable returns (bytes memory){
        address payable target = address(uint160(getContract(contractName)));
        //assert(target != address payable(0), 'Target contract is not registered'); //This check is already done in ContractManager

        bytes20 sender = bytes20(msg.sender);
        uint256 len = payload.length;
        bytes memory payloadExtra = new bytes(len+20);
        uint256 i;
        for(i = 0; i < len; i++){
            payloadExtra[i] = payload[i];
        }
        for(i = 0; i < 20; i++){
            payloadExtra[len+i] = sender[i];
        }

        (bool success, bytes memory result) = target.call.value(msg.value)(payloadExtra);
        require(success, 'Call failed');
        return result;
    }



}
