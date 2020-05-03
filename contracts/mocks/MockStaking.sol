pragma solidity ^0.5.5;

import "../libs/SafeMath.sol";
import "../interfaces/ERC20Standard.sol";

contract MockStaking {
    using SafeMath for uint256;

    ERC20Standard public superDaoToken;

    struct Account {
        uint256[] activeLockIds;
        uint256 lastLockId;
        mapping (uint256 => uint256) locks;
        History stakedHistory;
    }

    struct Checkpoint {
        uint256 time;
        uint256 value;
    }

    struct History {
        Checkpoint[] history;
    }

    mapping (address => Account) internal accounts;
    History internal totalStakedHistory;
  
    function initialize(address _superDaoToken) external {
        superDaoToken = ERC20Standard(_superDaoToken);
    }

    /**
     * @notice Stakes `_amount` tokens, transferring them from `msg.sender`
     * @param _amount Number of tokens staked
     */
    function stake(uint256 _amount) external {
       // staking 0 tokens is invalid
        require(_amount > 0);

        // checkpoint updated staking balance
        _modifyStakeBalance(msg.sender, _amount, true);

        // checkpoint total supply
        _modifyTotalStaked(_amount, true);

        // pull tokens into Staking contract
        require(superDaoToken.transferFrom(msg.sender, address(this), _amount));
    }

    /**
     * @notice Unstakes `_amount` tokens, returning them to the user
     * @param _amount Number of tokens staked
     */
    function unstake(uint256 _amount) external {
        // unstaking 0 tokens is not allowed
        require(_amount > 0);

        // checkpoint updated staking balance
        _modifyStakeBalance(msg.sender, _amount, false);

        // transfer tokens
        require(superDaoToken.transfer(msg.sender, _amount));
    }

    /**
     * @notice Get last time `_accountAddress` modified its staked balance
     * @param _accountAddress Account requesting for
     * @return Last block number when account's balance was modified
     */
    function lastStakedFor(address _accountAddress) external view returns (uint256) {
        uint256 length = accounts[_accountAddress].stakedHistory.history.length;

        if (length > 0) {
            return accounts[_accountAddress].stakedHistory.history[length - 1].time;
        }

        return 0;
    }


    /**
     * @notice Get the amount of tokens staked by `_accountAddress`
     * @param _accountAddress The owner of the tokens
     * @return The amount of tokens staked by the given account
     */
    function totalStakedFor(address _accountAddress) public view returns (uint256) {
        // we assume it's not possible to stake in the future
        uint256 length = accounts[_accountAddress].stakedHistory.history.length;
        if (length > 0) {
            return accounts[_accountAddress].stakedHistory.history[length - 1].value;
        }

        return 0;
    }

    function _modifyStakeBalance(address _accountAddress, uint256 _by, bool _increase) internal {
        uint256 currentStake = totalStakedFor(_accountAddress);

        uint256 newStake;
        if (_increase) {
            newStake = currentStake.add(_by);
        } else {
            newStake = currentStake.sub(_by);
        }

        // add new value to account history
        accounts[_accountAddress].stakedHistory.history.push(Checkpoint(block.number, newStake));
    }

    function _modifyTotalStaked(uint256 _by, bool _increase) internal {
        uint256 currentStake = totalStaked();

        uint256 newStake;
        if (_increase) {
            newStake = currentStake.add(_by);
        } else {
            newStake = currentStake.sub(_by);
        }

        // add new value to total history
        totalStakedHistory.history.push(Checkpoint(block.number, newStake));
    }

     /**
     * @notice Get the total amount of tokens staked by all users
     * @return The total amount of tokens staked by all users
     */
    function totalStaked() public view returns (uint256) {
        // we assume it's not possible to stake in the future

        uint256 length = totalStakedHistory.history.length;
        if (length > 0) {
            return totalStakedHistory.history[length - 1].value;
        }

        return 0;
    }
}



    
