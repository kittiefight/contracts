pragma solidity ^0.5.5;

interface IStaking {
    //function unlock(address _accountAddress, uint256 _lockId) external;
    function stake(uint256 _amount) external;
    function unstake(uint256 _amount) external;
    function totalStakedFor(address _accountAddress) external view returns (uint256);
    //function totalStakedForAt(address _accountAddress, uint256 _blockNumber) external view returns (uint256);
    function lastStakedFor(address _accountAddress) external view returns (uint256);
    function totalStakedAt(uint256 _blockNumber) external view returns (uint256);
    function totalStaked() external view returns (uint256);

}