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

        uint256 len = payload.length;
        bytes memory payloadWithSender = new bytes(len+20);

        assembly {

            //write msg.sender to the end of array
            let ptr := add(payloadWithSender, add(len, /*32-12*/20)) //this may rewrite frist 32 bytes with length, so we need to update them later
            mstore(ptr, caller)
            mstore(payloadWithSender, add(len, 20)) //write payload length, which may be damaged on previous step

            // find payload
            calldatacopy(0x20, /*4+32*/ 36, 32)     //load position of second argument to 0x20 in arguments block
            let payloadPos := add(mload(0x20), 4)   //add offset of arguments block

            // copy payload
            ptr := add(payloadWithSender, 32)               //skip header of the array
            calldatacopy(ptr, add(payloadPos, 32), len)

        }

        (bool success, bytes memory result) = target.call.value(msg.value)(payloadWithSender);
        require(success, 'Proxied call failed');
        return result;
    }
}
