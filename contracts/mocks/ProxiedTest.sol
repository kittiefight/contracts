pragma solidity ^0.5.5;

import "../modules/proxy/Proxied.sol";
import "../authority/Guard.sol";

contract ProxiedTest is Proxied, Guard {
    event TestCalled(bytes newPayload, uint256 ethReceived, address sender);

    bytes public lastPayload;

    function testFunction(bytes calldata payload) onlyProxy payable external {
        lastPayload = payload;
        address sender = getOriginalSender();
        emit TestCalled(payload, msg.value, sender);
    }


}
