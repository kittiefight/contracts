pragma solidity ^0.5.5;

import "../modules/proxy/Proxied.sol";

contract ProxiedTest is Proxied {
    event PayloadChanged(bytes newPayload, uint256 ethReceived);

    bytes public lastPayload;

    function testFunction(bytes calldata payload) onlyProxy payable external {
        lastPayload = payload;
        emit PayloadChanged(payload, msg.value);
    }

}
