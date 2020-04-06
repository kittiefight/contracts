pragma solidity ^0.5.5;

import "../libs/StringUtils.sol";

contract StringUtilsTest {
    using StringUtils for string;
    using StringUtils for uint256;

    function concat(string memory a, string memory b) public pure returns (string memory) {
        return a.concat(b);
    }
    function fromUint256(uint256 x) public pure returns (string memory) {
        return x.fromUint256();
    }
    function fromUint256(uint256 x, uint256 decimals, uint256 precision) public pure returns (string memory) {
        return x.fromUint256(decimals, precision);
    }
}
