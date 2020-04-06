pragma solidity ^0.5.5;

import "../libs/StringUtils.sol";

contract StringUtilsTest {
    using StringUtils for string;

    function concat(string memory a, string memory b) public pure returns (string memory) {
        return a.concat(b);
    }
}
