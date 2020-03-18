pragma solidity ^0.5.5;

interface IStaking {
    function unlock(address _accountAddress, uint256 _lockId) external;
    function totalStakedFor(address _accountAddress) external view returns (uint256);
}