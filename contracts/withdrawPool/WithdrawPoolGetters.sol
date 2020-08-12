pragma solidity ^0.5.5;

import "../modules/proxy/Proxied.sol";
import "../authority/Guard.sol";
import "../modules/databases/GenericDB.sol";
import "../libs/SafeMath.sol";

contract WithdrawPoolGetters is Proxied, Guard {
    using SafeMath for uint256;

    GenericDB public genericDB;

    function initialize() external onlyOwner {
        genericDB = GenericDB(proxy.getContract(CONTRACT_NAME_GENERIC_DB));
    }

    /*                                                 GETTER FUNCTIONS                                               */
    /*                                                      START                                                     */
    /* ============================================================================================================== */

    /**
     * @dev This function is returning the Ether that has been allocated to all pools.
     */
    function getEthPaidOut()
    external
    view
    returns(uint256)
    {
        return genericDB.getUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL_YIELDS,
            keccak256(abi.encode("totalEthPaidOut"))
          );
    }

    /**
     * @dev This function is returning the total number of Stakers that claimed from this contract.
     */
    function getNumberOfTotalStakers()
    external
    view
    returns(uint256)
    {
        return genericDB.getUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL_YIELDS,
            keccak256(abi.encode("noOfTotalStakers"))
          );
    }

    // get the pool ID of the currently active pool
    // The ID of the active pool is the same as the ID of the active epoch
    function getActivePoolID()
        public
        view
        returns (uint256)
    {
        return genericDB.getUintStorage(CONTRACT_NAME_TIMEFRAME, keccak256(abi.encode("activeEpoch")));
    }

    // get the initial ether available in a pool
    function getInitialETH(uint256 _poolID)
        public
        view
        returns (uint256)
    {
        return genericDB.getUintStorage(
            CONTRACT_NAME_ENDOWMENT_DB,
            keccak256(abi.encodePacked(_poolID, "InitialETHinPool"))
          );
    }

    // get number of stakers who have received yields from a pool with _poolID
    function getAllClaimersForPool(uint256 _poolID)
        public
        view
        returns (uint256)
    {
        return genericDB.getUintStorage(
            CONTRACT_NAME_WITHDRAW_POOL_YIELDS,
            keccak256(abi.encodePacked(_poolID, "totalStakersClaimed"))
        );
    }

    function getUnlocked(uint256 _poolID)
    public
    view
    returns(bool)
    {
        return genericDB.getBoolStorage(
            CONTRACT_NAME_WITHDRAW_POOL,
            keccak256(abi.encodePacked(_poolID, "unlocked")));
    }

     /**
      * @dev return the time remaining (in seconds) until time available for claiming the current pool
      * only current pool can be claimed
      */
     function timeUntilClaiming() public view returns (uint256) {
         uint256 epochID = getActivePoolID();
         uint256 claimTime = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epochID, "restDayStart")));
         if (claimTime > now) {
             return claimTime.sub(now);
         } else {
             return 0;
         }
     }

     /**
      * @dev return the time remaining (in seconds) until time for dissolving the current pool
      * If the pool is already dissolved, returns 0.
      */
     function timeUntilPoolDissolve() public view returns (uint256) {
         uint256 epochID = getActivePoolID();
         uint256 dissolveTime = genericDB.getUintStorage(
            CONTRACT_NAME_TIMEFRAME,
            keccak256(abi.encodePacked(epochID, "restDayEnd")));
         if (dissolveTime > now) {
             return dissolveTime.sub(now);
         } else {
             return 0;
         }
     }

    /*                                                 GETTER FUNCTIONS                                               */
    /*                                                       END                                                      */
    /* ============================================================================================================== */

}