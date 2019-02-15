pragma solidity 0.4.21;

/**
 * Base class contracts willing to accept ERC223 token transfers must conform to.
 *
 * _from: the origin address from whose balance the tokens are sent
 *          - For transfer(), origin = msg.sender
 *          - For transferFrom() origin = _from to token contract
 * Value is the amount of tokens sent
 * Data is arbitrary data sent with the token transfer. Simulates ether tx.data
 *
 * From, and value shouldn't be trusted unless the token contract is trusted.
 */

interface ERC223Receiver {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}
