/**
 * @title HitsResolveAlgo
 *
 * @author @kittieFIGHT @ola
 *
 */
//modifier class (DSAuth )
//Event class ( DSNote )
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
pragma solidity ^0.5.5;
import "../../libs/SafeMath.sol";
import "../proxy/Proxied.sol";
import "./Betting.sol";

/**
 * @title This contract is responsible to generate the final random number for use in 
 * selecting the actual final values within the table values 
 * to be assigned to the final attack list for any specific game instance in GameManager.
 * and maintains a list of Game ID to random seed input combinations.
 * @author @ziweidream
 */

contract HitsResolve is Proxied {
    using SafeMath for uint256;

    Betting public betting;

    // maintains a list of Game ID to random seed input combination
    mapping(uint256 => uint256) public currentRandom;

    function initialize() external onlyOwner {
        betting = Betting(proxy.getContract(CONTRACT_NAME_BETTING));
    }

    /**
     * @author @ziweidream
     * @notice generates a random number from 0 to 100 based on the last block hash, blocktime, block difficulty, and seed
     * @return The random number generated
     */
    function randomGen(uint256 seed) public view returns (uint256 randomNumber) {
        seed++;
        randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number-1), block.timestamp, block.difficulty, seed)))%100;
        if (randomNumber == 100) {
            randomNumber = 99;
        }
    }

    /**
     * @author @ziweidream
     * @notice generates a number from 0 to 2^n based on the last n blocks and seed
     * @return The random number generated
     */
    function multiBlockRandomGen(uint256 seed, uint256 size) public view returns (uint256) {
        uint256 n = 0;
        for (uint256 i = 0; i < size; i++) {
            if (uint256(keccak256(abi.encodePacked(blockhash(block.number-i-1), seed)))%2==0) {
                n += 2**i;
            }
        }
        return n;
    }

    /**
     * @author @ziweidream
     * @notice combine random input from bets with previous combined output (currentRandom number)
     * of sepcific GAMEID
     * @dev currentRandom number is ZERO if there was no previous bet
     * @return the most current random number associated with specific gameID
     */
    function calculateCurrentRandom(uint256 gameID, uint256 playerBet) public returns (uint256 currentRandomNum) {
        uint256 seed = playerBet.add(currentRandom[gameID]);
        currentRandomNum = randomGen(seed);
        currentRandom[gameID] = currentRandomNum;
    }

    /**
     * @author @ziweidream
     * @notice randomly chooses set of values to hitTypes of sepcific GAMEID
     * @return list of seven values to determine final values of attacks in Betting module
     */
    function finalizeHitTypeValues(uint256 _gameID, uint256 _seed) 
    public view
    returns (uint256[7] memory hitTypeVals) //uint256 lowPunch, uint256 lowKick, uint256 lowThunder, uint256 hardPunch, uint256 hardKick, uint256 hardThunder, uint256 slash) 
        {
            (uint256 lowPunch, uint256 lowKick, uint256 lowThunder) = assignLowValues(_gameID, _seed);
            (uint256 hardPunch, uint256 hardKick, uint256 hardThunder) = assignHighValues(_gameID, _seed);
            uint256 slash = assignSlashValue(_gameID, _seed);

            hitTypeVals[0] = lowPunch;
            hitTypeVals[1] = lowKick;
            hitTypeVals[2] = lowThunder;
            hitTypeVals[3] = hardPunch;
            hitTypeVals[4] = hardKick;
            hitTypeVals[5] = hardThunder;
            hitTypeVals[6] = slash;
        }

    /**
     * @author @ziweidream
     * @notice randomly assign values to Low Punch[1-100], Low Kick[101-200], and Low Thunder[201-300] hit types
     * @return set of random values assigned to low value hit types
     */
    function assignLowValues(uint256 _gameID, uint256 _seed) public view returns (uint256 lowPunch, uint256 lowKick, uint256 lowThunder) {
      uint256 nonce = currentRandom[_gameID];
      uint256 seed1 = _seed.add(nonce).add(1);
      uint256 seed2 = _seed.add(nonce).add(2);
      uint256 seed3 = _seed.add(nonce).add(3);
      lowPunch = randomGen(seed1).add(1);
      lowKick = randomGen(seed2).add(101);
      lowThunder = randomGen(seed3).add(201);
    }

     /**
     * @author @ziweidream
     * @notice randomly assign values to Hard Punch[301-400], Hard Kick[401-500], and Hard Thunder[501-600] hit types
     * @return set of random values assigned to high value hit types
     */
    function assignHighValues(uint256 _gameID, uint256 _seed) public view returns (uint256 hardPunch, uint256 hardKick, uint256 hardThunder) {
      uint256 nonce = currentRandom[_gameID];
      uint256 seed1 = _seed.add(nonce).add(1);
      uint256 seed2 = _seed.add(nonce).add(2);
      uint256 seed3 = _seed.add(nonce).add(3);
      hardPunch = randomGen(seed1).add(301);
      hardKick = randomGen(seed2).add(401);
      hardThunder = randomGen(seed3).add(501);
    }

    /**
     * @author @ziweidream
     * @notice randomly assign values to the slash type which can be either high [601-700] or low result [1-100] ranges
     * @return random value assigned to slash types
     */
    function assignSlashValue(uint256 _gameID, uint256 _seed) public view returns(uint256 slash) {
      uint256 nonce = currentRandom[_gameID];
      uint256 rand = multiBlockRandomGen(_seed, 1);
      uint256 seed = _seed.add(nonce).add(1);
      if (rand == 0) {
          slash = randomGen(seed).add(601);
      } else if (rand == 1) {
          slash = randomGen(seed);
      }
    }

    
    function calculateFinalDirectAttacksPointsLowValue(uint256 _gameId, address _supportedPlayer, uint256 _randomNum)
        public view
        returns(uint256 finalDirectAttacksPointsLowValue)
    {
        // finalizeGame() returns 7 values
        uint256[7] memory hitTypesVals = finalizeHitTypeValues(_gameId, _randomNum);

        // get the number of the direct attacks of each attack types of the given corner
        uint256[7] memory directAttacks = betting.getDirectAttacksScored(_gameId, _supportedPlayer);

        finalDirectAttacksPointsLowValue = hitTypesVals[0].mul(directAttacks[0]).mul(100)
                       .add(hitTypesVals[1].mul(directAttacks[1]).mul(100))
                       .add(hitTypesVals[2].mul(directAttacks[2]).mul(100));
    }

    function calculateFinalDirectAttacksPointsHighValue(uint256 _gameId, address _supportedPlayer, uint256 _randomNum)
        public view
        returns(uint256 finalDirectAttacksPointsHighValue)
    {
        // finalizeGame() returns 7 values
   
        uint256[7] memory hitTypesVals = finalizeHitTypeValues(_gameId, _randomNum);

        // get the number of the direct attacks of each attack types of the given corner
        uint256[7] memory directAttacks = betting.getDirectAttacksScored(_gameId, _supportedPlayer);

          finalDirectAttacksPointsHighValue = hitTypesVals[3].mul(directAttacks[3]).mul(100)
                       .add(hitTypesVals[4].mul(directAttacks[4]).mul(100))
                       .add(hitTypesVals[5].mul(directAttacks[5]).mul(100))
                       .add(hitTypesVals[6].mul(directAttacks[6]).mul(100));


    }

    function calculateFinalBlockedAttacksPointsLowValue(uint256 _gameId, address _supportedPlayer, uint256 _randomNum)
        public view
        returns(uint256 finalBlockedAttacksPointsLowValue)
    {
         // finalizeGame() returns 7 values
        uint256[7] memory hitTypesVals = finalizeHitTypeValues(_gameId, _randomNum);

        // get the number of the blocked attacks of each attack types of the given corner in a game

        uint256[7] memory blockedAttacks = betting.getBlockedAttacksScored(_gameId, _supportedPlayer);

         // calculate the final points for the given corner in a game
         finalBlockedAttacksPointsLowValue = (hitTypesVals[0].mul(blockedAttacks[0]).mul(25))
                       .add(hitTypesVals[1].mul(blockedAttacks[1]).mul(25))
                       .add(hitTypesVals[2].mul(blockedAttacks[2]).mul(25));
    }

    function calculateFinalBlockedAttacksPointsHighValue(uint256 _gameId, address _supportedPlayer, uint256 _randomNum)
        public view
        returns(uint256 finalBlockedAttacksPointsHighValue)
    {
         // finalizeGame() returns 7 values
        uint256[7] memory hitTypesVals = finalizeHitTypeValues(_gameId, _randomNum);

        // get the number of the blocked attacks of each attack types of the given corner in a game
        uint256[7] memory blockedAttacks = betting.getBlockedAttacksScored(_gameId, _supportedPlayer);

         // calculate the final points for the given corner in a game
         finalBlockedAttacksPointsHighValue = hitTypesVals[3].mul(blockedAttacks[3]).mul(25)
                       .add(hitTypesVals[4].mul(blockedAttacks[4]).mul(25))
                       .add(hitTypesVals[5].mul(blockedAttacks[5]).mul(25))
                       .add(hitTypesVals[6].mul(blockedAttacks[6]).mul(25));

    }

    function calculateFinalPoints(uint256 _gameId, address _supportedPlayer, uint256 _randomNum) 
        public view
        returns(uint256 finalPoints) 
    {
         // calculate the final points for the given corner in a game
         uint256 directAttacksLowValue = calculateFinalDirectAttacksPointsLowValue(_gameId, _supportedPlayer, _randomNum);
         uint256 directAttacksHighValue = calculateFinalDirectAttacksPointsHighValue(_gameId, _supportedPlayer, _randomNum);
         uint256 blockedAttacksLowValue = calculateFinalBlockedAttacksPointsLowValue(_gameId, _supportedPlayer, _randomNum);
         uint256 blockedAttacksHighValue = calculateFinalBlockedAttacksPointsHighValue(_gameId, _supportedPlayer, _randomNum);

         finalPoints = directAttacksLowValue + directAttacksHighValue + blockedAttacksLowValue + blockedAttacksHighValue;
    }

}
