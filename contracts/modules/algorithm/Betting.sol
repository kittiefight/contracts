/**
 * @title Betting
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

import "../proxy/Proxied.sol";
import "../../authority/Guard.sol";
import "../../libs/SafeMath.sol";
import "./RarityCalculator.sol";

/**
 * @title This contract is responsible to carry out the betting module in a game
 * @author @ziweidream
 */

contract Betting is Proxied, Guard {
    using SafeMath for uint256;

    ///fight map for a game with a specific gameId
     struct HitType {
        bytes32 hash;
        string attack;
     }
    mapping(uint256 => HitType[]) public fightMap;

    /// total number of direct attacks of each hitType of the given corner in a game
     mapping(uint256 => mapping(address => uint256[7])) public directAttacksScored;
    /// total number of blocked attacks of each hitType of the given corner in a game
    mapping(uint256 => mapping(address => uint256[7])) public blockedAttacksScored;
    /// individual bets placed by the given corner in a game
    mapping(uint256 => mapping(address => uint256[])) public bets;
    /// timestamp of the last bet placed by the given corner in a game
    mapping(uint256 => mapping(address => uint256)) public lastBetTimestamp;
    /// current defense level of the given corner in a game
    mapping(uint256 => mapping(address => uint256)) public defenseLevel;

    // setFightMap() is internal. Temporarily set as public for truffle test purpose.
    /**
     * @author @ziweidream
     * @notice set fight map for a game with a specific gameId
     * @param _gameId the gameID of the game for which the fight map is generated
     * @param _randomRed random number generated when the red corner presses Button start
     * @param _randomBlack black number generated when the black corner presses Button start
     */
    function setFightMap(uint256 _gameId, uint256 _randomRed, uint256 _randomBlack)
        public //temporarily set as public just for truffle test purpose
        //internal
    {
        uint randomNum = _randomRed.add(_randomBlack);
        bytes32 hashLowPunch = keccak256(abi.encodePacked(randomNum, "lowPunch"));
        bytes32 hashLowKick = keccak256(abi.encodePacked(randomNum, "lowKick"));
        bytes32 hashLowThunder = keccak256(abi.encodePacked(randomNum, "lowThunder"));
        bytes32 hashHardPunch = keccak256(abi.encodePacked(randomNum, "hardPunch"));
        bytes32 hashHardKick = keccak256(abi.encodePacked(randomNum, "hardKick"));
        bytes32 hashHardThunder = keccak256(abi.encodePacked(randomNum, "hardThunder"));
        bytes32 hashSlash = keccak256(abi.encodePacked(randomNum, "slash"));
        fightMap[_gameId].push(HitType(hashLowPunch, "lowPunch"));
        fightMap[_gameId].push(HitType(hashLowKick, "lowKick"));
        fightMap[_gameId].push(HitType(hashLowThunder, "lowThunder"));
        fightMap[_gameId].push(HitType(hashHardPunch, "hardPunch"));
        fightMap[_gameId].push(HitType(hashHardKick, "hardKick"));
        fightMap[_gameId].push(HitType(hashHardThunder, "hardThunder"));
        fightMap[_gameId].push(HitType(hashSlash, "slash"));

        emit FightMapGenerated(_gameId);
    }

    // setDirectAttacksScored() is internal. Temporarily set as public for truffle test purpose.
    /**
     * @author @ziweidream
     * @notice record the total number of direct attacks of each hitType of the given corner in a game
     * @param _gameId the gameID of the game
     * @param _player the given corner in this game for whom the total number of the direct attacks are recorded
     * @param index the index in the mapping directAttacksScored. The index is obtained in function getAttackType()
     */
    function setDirectAttacksScored(
          uint256 _gameId,
          address _player,
          uint256 index
          )
          public //temporarily set as public just for truffle testing purpose
          //internal
          {
            directAttacksScored[_gameId][_player][index] = directAttacksScored[_gameId][_player][index].add(1);
          }

    // setBlockedAttacksScored() is internal. Temporarily set as public for truffle test purpose.
    /**
     * @author @ziweidream
     * @notice record the total number of blocked attacks of each hitType of the given corner in a game
     * @param _gameId the gameID of the game
     * @param _player the given corner in this game for whom the total number of the blocked attacks are recorded
     * @param index the index in the mapping blockedAttacksScored. The index is obtained in function getAttackType()
     */
    function setBlockedAttacksScored(
          uint256 _gameId,
          address _player,
          uint256 index
          )
          public // temporarily set as public just for truffle testing purpose
          //internal
          {
            blockedAttacksScored[_gameId][_player][index] = blockedAttacksScored[_gameId][_player][index].add(1);
          }

    // get the total number of direct attacks of each hitType of the given corner in a game
    /**
     * @author @ziweidream
     * @notice get the total number of direct attacks of each hitType of the given corner in a game
     * @param _gameId the gameID of the game
     * @param _player the given corner in this game for whom the total number of the direct attacks are obtained
     * @return an array of fixed size 7 directAttacks, which contains the total number of direct attacks of each hitType
     * of the given corner in this game
     */
    function getDirectAttacksScored(uint256 _gameId, address _player)
        public
        view
        returns(
            uint256[7] memory directAttacks
            )
        {
            uint256 totalLowPunch = directAttacksScored[_gameId][_player][0];
            uint256 totalLowKick = directAttacksScored[_gameId][_player][1];
            uint256 totalLowThunder = directAttacksScored[_gameId][_player][2];
            uint256 totalHardPunch = directAttacksScored[_gameId][_player][3];
            uint256 totalHardKick = directAttacksScored[_gameId][_player][4];
            uint256 totalHardThunder = directAttacksScored[_gameId][_player][5];
            uint256 totalSlash = directAttacksScored[_gameId][_player][6];
            directAttacks[0] = totalLowPunch;
            directAttacks[1] = totalLowKick;
            directAttacks[2] = totalLowThunder;
            directAttacks[3] = totalHardPunch;
            directAttacks[4] = totalHardKick;
            directAttacks[5] = totalHardThunder;
            directAttacks[6] = totalSlash;
          }

      // get the total number of blocked attacks of each hitType of the given corner in a game
      /**
       * @author @ziweidream
       * @notice get the total number of blocked attacks of each hitType of the given corner in a game
       * @param _gameId the gameID of the game
       * @param _player the given corner in this game for whom the total number of the blocked attacks are obtained
       * @return an array of fixed size 7 blockedAttacks, which contains the total number of blocked attacks of each hitType
       * of the given corner in this game
       */
      function getBlockedAttacksScored(uint256 _gameId, address _player)
          public
          view
          returns(
              uint256[7] memory blockedAttacks
              )
          {
              uint256 totalLowPunch = blockedAttacksScored[_gameId][_player][0];
              uint256 totalLowKick = blockedAttacksScored[_gameId][_player][1];
              uint256 totalLowThunder = blockedAttacksScored[_gameId][_player][2];
              uint256 totalHardPunch = blockedAttacksScored[_gameId][_player][3];
              uint256 totalHardKick = blockedAttacksScored[_gameId][_player][4];
              uint256 totalHardThunder = blockedAttacksScored[_gameId][_player][5];
              uint256 totalSlash = blockedAttacksScored[_gameId][_player][6];
              blockedAttacks[0] = totalLowPunch;
              blockedAttacks[1] = totalLowKick;
              blockedAttacks[2] = totalLowThunder;
              blockedAttacks[3] = totalHardPunch;
              blockedAttacks[4] = totalHardKick;
              blockedAttacks[5] = totalHardThunder;
              blockedAttacks[6] = totalSlash;
          }

    // fillBets() is internal. Temporarily set as public for truffle test purpose.
   /**
    * @author @ziweidream
    * @notice record the bet ether amount of each individual bet placed by the given corner
    * in a game with a specific gameId
    * @param _gameId the gameID of the game
    * @param _player the given corner in this game for whom the individual bet ether amount is recorded
    * @param _betAmount the ether amount of the bet placed by the given corner
    */
    function fillBets(uint256 _gameId, address _player, uint256 _betAmount)
        public  // temporarily set as public just for truffle testing purpose
        //internal
    {
      bets[_gameId][_player].push(_betAmount);
    }

   /**
    * @author @ziweidream
    * @notice get the number of total bets placed by the given corner in a game
    * with a specific gameId
    * @param _gameId the gameID of the game
    * @param _player the given corner in this game whose individual bet ether amount is recorded
    * @return the number of total bets placed by the given corner in a game
    */
    function getNumberOfBets(uint256 _gameId, address _player)
       public
       view
       returns(uint256 num)
    {
        num = bets[_gameId][_player].length;
    }

    // get last 5 bet amount of the given corner
   /**
    * @author @ziweidream
    * @notice get the ether amount of the last 5 bets placed by the given corner in a game
    * with a specific gameId
    * @dev lastBet1 is the last bet, lastBet2 is the second last bet, and so forth
    * @param _gameId the gameID of the game
    * @param _player the given corner in this game whose individual bet ether amount is recorded
    * @return the last 5 bet ether amount by the given corner in a game
    */
    function getLastFourBets(uint256 _gameId, address _player)
        public
        view
        returns(uint256 lastBet4, uint256 lastBet3, uint256 lastBet2, uint256 lastBet1)
    {
      uint256 arrLength = bets[_gameId][_player].length;
      require(arrLength > 3);
      lastBet4 = bets[_gameId][_player][arrLength.sub(4)];
      lastBet3 = bets[_gameId][_player][arrLength.sub(3)];
      lastBet2 = bets[_gameId][_player][arrLength.sub(2)];
      lastBet1 = bets[_gameId][_player][arrLength.sub(1)];
  }

    // setLastBetTimestamp() is internal. Temporarily set as public for truffle test purpose.
    /**
    * @author @ziweidream
    * @notice record the last bet timestamp for the given corner in a game with a specific gameId
    * @param _gameId the gameID of the game
    * @param _player the given corner in this game whose last bet timestamp is recorded
    * @param _lastBetTimestamp the timestamp of the last bet placed by the given corner in the game
    */
    function setLastBetTimestamp(uint256 _gameId, address _player, uint256 _lastBetTimestamp)
        public //temporarily set as public just for truffle testing purpose
        //internal
    {
        lastBetTimestamp[_gameId][_player] = _lastBetTimestamp;
    }

   /**
    * @author @ziweidream
    * @notice record the current defense level of the given corner in a game with a specific gameId
    * @param _gameId the gameID of the game
    * @param _player the given corner in this game for whom the defense level is recorded
    */
    function setDefenseLevel(uint256 _gameId, address _player, uint _defense)
        public   // temporarily set as public just for truffle testing purpose
        //internal
    {
        defenseLevel[_gameId][_player] = _defense;
    }

    // temporarily comment out onlyContract(CONTRACT_NAME_GAMEMANAGER) until GameManager.sol is furhter defined/developed
    /**
    * @author @ziweidream
    * @notice record the original defense level of the given corner in a game with a specific gameId
    * @dev this function is only called by GameManager contract
    * @param _gameId the gameID of the game
    * @param _player the address of the given corner in this game for whom the defense level is recorded
    * @param _originalDefenseLevel the original defense level of the given corner, which is calculated in
    * the function startGame() in GameManager
    */
    function setOriginalDefenseLevel(uint256 _gameId, address _player, uint256 _originalDefenseLevel)
        public
        //onlyContract(CONTRACT_NAME_GAMEMANAGER)
    {
        setDefenseLevel(_gameId, _player, _originalDefenseLevel);
    }

   /**
    * @author @ziweidream
    * @notice randomly select attack types from low values column or high values column depending on
    * the bet ether amount by the given corner in a game with a specific gameId
    * @param _gameId the gameID of the game
    * @param _supportedPlayer the given corner in this game for whom the attack type is randomly selected
    * @param _lastBetAmount the last bet ether amount placed by the supported player in the game
    * @param _randomNum the random number generated by the front end when Button bet is pressed by the given corner
    * @return the attackType randomly selected for the given corner, the attackHash for the attackType selected,
    * and the index of the attackHash returned in the fight map
    */
    function getAttackType(
        uint256 _gameId,
        address _supportedPlayer,
        uint256 _lastBetAmount,
        uint256 _randomNum)
        public view
        returns (
            string memory attackType,
            bytes32 attackHash,
            uint256 index
        ){
        (,,,uint256 prevBetAmount) = getLastFourBets(_gameId, _supportedPlayer);
        // lower ether than previous bet? one attack is chosen randomly from lowAttacksColumn
        if (_lastBetAmount <= prevBetAmount) {
            uint256 diceLowValues = randomGen(_randomNum);
            if (diceLowValues <= 33) {
                attackType = fightMap[_gameId][0].attack;
                attackHash = fightMap[_gameId][0].hash;
                index = 0;
            } else if (diceLowValues <= 66 && diceLowValues > 33) {
                attackType = fightMap[_gameId][1].attack;
                attackHash = fightMap[_gameId][1].hash;
                index = 1;
            } else if (diceLowValues > 66) {
                attackType = fightMap[_gameId][2].attack;
                attackHash = fightMap[_gameId][2].hash;
                index = 2;
            }
        } else if (_lastBetAmount > prevBetAmount) {
             // higher ether than previous bet? one attack is chosen randomly from highAttacksColumn
            uint256 diceHardValues = randomGen(_randomNum);
            if (diceHardValues <= 25) {
                attackType = fightMap[_gameId][3].attack;
                attackHash = fightMap[_gameId][3].hash;
                index = 3;
            } else if (diceHardValues > 25 && diceHardValues <= 50) {
                attackType = fightMap[_gameId][4].attack;
                attackHash = fightMap[_gameId][4].hash;
                index = 4;
            } else if (diceHardValues > 50 && diceHardValues <= 75) {
                attackType = fightMap[_gameId][5].attack;
                attackHash = fightMap[_gameId][5].hash;
                index = 5;
            } else if (diceHardValues > 75) {
                attackType = fightMap[_gameId][6].attack;
                attackHash = fightMap[_gameId][6].hash;
                index = 6;
            }
        }
        return (attackType, attackHash, index);
    }

    // determine whether the attack type is blocked or direct
    // if opponent's defence level = 0, all attacks are direct
    // if opponent has been inactive for more than 5 seconds since last bet, attack is direct. Otherwise the attack is blocked.
   /**
    * @author @ziweidream
    * @notice determine whether the attack type by the supported player is blocked or direct in a game with a specific gameId
    * @param _gameId the gameID of the game
    * @param _opponentPlayer the address of the opponent player in this game
    * @return true if the attack type is blocked, false if it is direct
    */
    function isAttackBlocked(uint256 _gameId, address _opponentPlayer) public view returns(bool) {
        uint256 _lastBetTimestamp = lastBetTimestamp[_gameId][_opponentPlayer];
        // If opponent has been inactive for more than 5 seconds since last bet, attack is direct.
        // Otherwise it is blocked.
        if(_lastBetTimestamp >= now.sub(5)) {
            return true;
        }
        return false;
    }

     // the defense level of an oppoent is reduced each time
     // a bet is received from attacker and the last five bets are compared on the condition to see
     // if each bet was bigger than the previous bet in progression.
     // reduceDefenseLevel() is internal. Temporarily set as public for truffle test purpose.
   /**
    * @author @ziweidream
    * @notice reduce the defense level of the opponent if each of the last 5 bets ether amount from
    * the attacker was consecutively bigger than the previous one in a game with a specific gameId
    * @param _gameId the gameID of the game
    * @param _supportedPlayer the address of the supported player in this game
    * whose last 5 bets ether amount are compared
    * @param _opponentPlayer the address of the opponent player in this game
    * whose defense level is reduced if contidions stated above are met
    * @return the defense level of the opponent player in the game
    */
     function reduceDefenseLevel(
        uint256 _gameId,
        uint256 _lastBetAmount,
        address _supportedPlayer,
        address _opponentPlayer
        )
        public  // temporarily set as public just for truffle test purpose
        //internal
        returns (
          uint256 defenseLevelOpponent
        )
        {
        require(defenseLevel[_gameId][_opponentPlayer] > 0, "Defense level is already zero");
        (uint256 lastBet4, uint256 lastBet3, uint256 lastBet2, uint256 lastBet1) = getLastFourBets(_gameId, _supportedPlayer);
        if (_lastBetAmount > lastBet1 && lastBet1 > lastBet2 && lastBet2 > lastBet3 && lastBet3 > lastBet4) {
            defenseLevelOpponent = defenseLevel[_gameId][_opponentPlayer].sub(1);
            setDefenseLevel(_gameId, _opponentPlayer, defenseLevelOpponent);
        }
        return defenseLevelOpponent;
    }

    /**
     * @author @ziweidream
     * @notice generates a random number from 0 to 100 based on the last block hash, blocktime, block difficulty, and seed
     * @return The random number generated
     */
    function randomGen(uint256 seed) public view returns (uint256 randomNumber) {
        seed = seed.add(1);
        randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number.sub(1)), block.timestamp, block.difficulty, seed)))%100;
    }

    // temporarily comment out onlyContract(CONTRACT_NAME_GAMEMANAGER) 
   /**
    * @author @ziweidream
    * @notice generates a fight map for a game with a specific gameId, and calculates the original defense levels
    * of both corners in this game
    * @dev this function can only be called by the GameManager contract
    * @param _gameId the gameID of the game
    * @param _randomRed the random number generated when the Red corner presses the Button Bet
    * @param _randomBlack the random number generated when the Black corner presses the Button Bet
    */
    function startGame(
        uint256 _gameId,
        uint256 _randomRed,
        uint256 _randomBlack
        )
        public
        //onlyContract(CONTRACT_NAME_GAMEMANAGER)
    {
        setFightMap(_gameId, _randomRed, _randomBlack);
        emit GameStarted(_gameId);
    }

    // temporarily comment out onlyContract(CONTRACT_NAME_GAMEMANAGER)
   /**
    * @author @ziweidream
    * @notice determines the attack type, attackHash, and current opponent defense level partially
    * depending on the effect of each bet placed by the given corner in a game with a specific gameId
    * @dev this function can only be called by the GameManager contract
    * @param _gameId the gameID of the game
    * @param _bettor the address of the bettor who placed the bet
    * @param _lastBetAmount the last bet ether amount placed by the supported player in the game
    * @param _supportedPlayer the address of the supported player in the game
    * @param _opponentPlayer the address of the opponent player in the game
    * @param _randomNum the random number generated when the supported player presses Button Bet
    * in the game
    * @return the attack type and attackHash for the supported player,
    * and current defense level of the supported and the opponent player
    */
    function bet(
        uint256 _gameId,
        address _bettor,
        uint256 _lastBetAmount,
        address _supportedPlayer,
        address _opponentPlayer,
        uint256 _randomNum)
        public
    {
        (string memory attackType, bytes32 attackHash, uint256 index) = getAttackType(_gameId, _supportedPlayer, _lastBetAmount, _randomNum);

        uint256 defenseLevelOpponent = defenseLevel[_gameId][_opponentPlayer];

        uint256 numberOfBets = getNumberOfBets(_gameId, _supportedPlayer);

        if (defenseLevelOpponent > 0 && numberOfBets > 3) {
           defenseLevelOpponent = reduceDefenseLevel(_gameId, _lastBetAmount, _supportedPlayer, _opponentPlayer);
        }

        if (defenseLevelOpponent == 0) {
            setDirectAttacksScored(_gameId, _supportedPlayer, index);
        } else if(defenseLevelOpponent > 0 && isAttackBlocked(_gameId, _opponentPlayer)) {
            setBlockedAttacksScored(_gameId, _supportedPlayer, index);
        } else {
            setDirectAttacksScored(_gameId, _supportedPlayer, index);
        }

        setLastBetTimestamp(_gameId, _supportedPlayer, now);
        fillBets(_gameId, _supportedPlayer, _lastBetAmount);

        uint256 defenseLevelSupportedPlayer = defenseLevel[_gameId][_supportedPlayer];

        emit BetPlaced(
            _gameId,
            _bettor,
            _lastBetAmount,
            _supportedPlayer,
            attackHash,
            attackType,
            defenseLevelSupportedPlayer,
            defenseLevelOpponent
            );
    }

    event GameStarted(uint256 indexed _gameId);

    event FightMapGenerated(uint256 indexed _gameId);

    event BetPlaced(
        uint256 indexed _gameId,
        address indexed _bettor,
        uint256 _lastBetAmount,
        address indexed _supportedPlyer,
        bytes32 attackHash,
        string attackType,
        uint256 defenseLevelSupportedPlayer,
        uint256 defenseLevelOpponent);
}
