pragma solidity ^0.5.5;

contract EndowmentTestable {
    uint public counter;

    function increment() public returns(bool) {
        counter++;
        return true;
    }
}
