pragma solidity ^0.5.5;

import "../modules/proxy/Proxied.sol";
import "../authority/Guard.sol";

contract ProxiedTest is Proxied, Guard {
    event TestCalledBytes(bytes payload, uint256 ethReceived, address sender);
    event TestCalledTwoArgs(uint256 arg1, address arg2, uint256 ethReceived, address sender);

    bytes public lastPayload;
    uint256 public lastArg1;
    address public lastArg2;
    address public lastSender;

    function testFunctionBytes(bytes calldata payload) onlyProxy payable external {
        lastPayload = payload;
        address sender = getOriginalSender();
        emit TestCalledBytes(payload, msg.value, sender);
    }

    function testFunctionTwoArgs(uint256 arg1, address arg2) onlyProxy payable external {
        lastArg1 = arg1;
        lastArg2 = arg2;
        lastSender = getOriginalSender();
        emit TestCalledTwoArgs(arg1, arg2, msg.value, lastSender);
    }

}
