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

contract Betting is Proxied, Guard {
    using SafeMath for uint256;

    //fight map for a game with a specific gameId
     struct HitType {
        bytes32 hash;
        string attack;
     }
    mapping(uint256 => HitType[]) public fightMap;

    // total number of direct attacks of each hitType of the given corner in a game
     mapping(uint256 => mapping(address => uint256[7])) public directAttacksScored;
     // total number of blocked attacks of each hitType of the given corner in a game
    mapping(uint256 => mapping(address => uint256[7])) public blockedAttacksScored;
    // individual bets placed by the given corner in a game
    mapping(uint256 => mapping(address => uint256[])) public bets;
   // timestamp of the last bet placed by the given corner in a game
    mapping(uint256 => mapping(address => uint256)) public lastBetTimestamp;
    // current defense level of the given corner in a game
    mapping(uint256 => mapping(address => uint256)) public defenseLevel;

    // setFightMap() is internal. Temporarily set as public for truffle test purpose.
    function setFightMap(uint256 _gameId, uint256 _randomRed, uint256 _randomBlack) public {
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
    }

    // setDirectAttacksScored() is internal. Temporarily set as public for truffle test purpose.
    // set the total number of direct attacks of each hitType of the given corner in a game
    function setDirectAttacksScored(
          uint256 _gameId,
          address _supportedPlayer,
          uint256 index
          )
          public {
            directAttacksScored[_gameId][_supportedPlayer][index] = directAttacksScored[_gameId][_supportedPlayer][index].add(1);
          }

    // setBlockedAttacksScored() is internal. Temporarily set as public for truffle test purpose.
    // set the total number of blocked attacks of each hitType of the given corner in a game
    function setBlockedAttacksScored(
          uint256 _gameId,
          address _supportedPlayer,
          uint256 index
          )
          public {
            blockedAttacksScored[_gameId][_supportedPlayer][index] = blockedAttacksScored[_gameId][_supportedPlayer][index].add(1);
          }
      
      // get the total number of direct attacks of each hitType of the given corner in a game
    function getDirectAttacksScored(uint256 _gameId, address _supportedPlayer)
        public
        view
        returns(
            uint256[7] memory directAttacks
            )
        {
            uint256 totalLowPunch = directAttacksScored[_gameId][_supportedPlayer][0];
            uint256 totalLowKick = directAttacksScored[_gameId][_supportedPlayer][1];
            uint256 totalLowThunder = directAttacksScored[_gameId][_supportedPlayer][2];
            uint256 totalHardPunch = directAttacksScored[_gameId][_supportedPlayer][3];
            uint256 totalHardKick = directAttacksScored[_gameId][_supportedPlayer][4];
            uint256 totalHardThunder = directAttacksScored[_gameId][_supportedPlayer][5];
            uint256 totalSlash = directAttacksScored[_gameId][_supportedPlayer][6];
            directAttacks[0] = totalLowPunch;
            directAttacks[1] = totalLowKick;
            directAttacks[2] = totalLowThunder;
            directAttacks[3] = totalHardPunch;
            directAttacks[4] = totalHardKick;
            directAttacks[5] = totalHardThunder;
            directAttacks[6] = totalSlash;
          }

      // get the total number of blocked attacks of each hitType of the given corner in a game
      function getBlockedAttacksScored(uint256 _gameId, address _supportedPlayer)
          public
          view
          returns(
              uint256[7] memory blockedAttacks
              )
          {
              uint256 totalLowPunch = blockedAttacksScored[_gameId][_supportedPlayer][0];
              uint256 totalLowKick = blockedAttacksScored[_gameId][_supportedPlayer][1];
              uint256 totalLowThunder = blockedAttacksScored[_gameId][_supportedPlayer][2];
              uint256 totalHardPunch = blockedAttacksScored[_gameId][_supportedPlayer][3];
              uint256 totalHardKick = blockedAttacksScored[_gameId][_supportedPlayer][4];
              uint256 totalHardThunder = blockedAttacksScored[_gameId][_supportedPlayer][5];
              uint256 totalSlash = blockedAttacksScored[_gameId][_supportedPlayer][6];
              blockedAttacks[0] = totalLowPunch;
              blockedAttacks[1] = totalLowKick;
              blockedAttacks[2] = totalLowThunder;
              blockedAttacks[3] = totalHardPunch;
              blockedAttacks[4] = totalHardKick;
              blockedAttacks[5] = totalHardThunder;
              blockedAttacks[6] = totalSlash;
          }

    // fillBets() is internal. Temporarily set as public for truffle test purpose.
    // record the bet amount of each individual bet of the given corner of a game with a specific gameId
    function fillBets(uint256 _gameId, address _supportedPlayer, uint256 _betAmount) public {
      bets[_gameId][_supportedPlayer].push(_betAmount);
    }

    // get last 5 bet amount of the given corner
    function getLastFiveBets(uint256 _gameId, address _supportedPlayer)
        public
        view
        returns(uint lastBet5, uint lastBet4, uint lastBet3, uint lastBet2, uint lastBet1)
    {
      uint256 arrLength = bets[_gameId][_supportedPlayer].length;
      lastBet5 = bets[_gameId][_supportedPlayer][arrLength.sub(5)];
      lastBet4 = bets[_gameId][_supportedPlayer][arrLength.sub(4)];
      lastBet3 = bets[_gameId][_supportedPlayer][arrLength.sub(3)];
      lastBet2 = bets[_gameId][_supportedPlayer][arrLength.sub(2)];
      lastBet1 = bets[_gameId][_supportedPlayer][arrLength.sub(1)];
  }

    // setLastBetTimestamp() is internal. Temporarily set as public for truffle test purpose.
    function setLastBetTimestamp(uint256 _gameId, address _supportedPlayer, uint256 _lastBetTimestamp) public {
        lastBetTimestamp[_gameId][_supportedPlayer] = _lastBetTimestamp;
    }

    // setDefenseLevel() is internal. Temporarily set as public for truffle test purpose.
    function setDefenseLevel(uint256 _gameId, address _player, uint256 _defenseLevel) public {
        defenseLevel[_gameId][_player] = _defenseLevel;
    }

    // randomly select attack types from low values column or high values column depending on the bet ether amount
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
        (,,,,uint256 prevBetAmount) = getLastFiveBets(_gameId, _supportedPlayer);
        // lower ether than previous bet? one attack is chosen randomly from lowAttacksColumn
        if (_lastBetAmount <= prevBetAmount) {
            uint256 diceLowValues = randomGen(_randomNum);
            if (diceLowValues <= 33) {
                attackType = fightMap[_gameId][0].attack;//attacksColumn[0];
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
    function isAttackBlocked(uint256 _gameId, address _opponentPlayer) public view returns(bool) {
        // get the last bet timestamp of the given corner
        uint256 _lastBetTimestamp = lastBetTimestamp[_gameId][_opponentPlayer];
        if(_lastBetTimestamp >= now.sub(5)) {
            return true;
        }
        return false;
    }

     // the defense level of an oppoent is reduced each time 
     // a bet is received from attacker and the last five bets are compared on the condition to see 
     // if each bet was bigger than the previous bet in progression.
     // reduceDefenseLevel() is internal. Temporarily set as public for truffle test purpose.
     function reduceDefenseLevel(
        uint256 _gameId,
        address _supportedPlayer,
        address _opponentPlayer
        )
        public
        returns (
          uint256 defenseLevelOpponent
        )
        {
        require(defenseLevel[_gameId][_opponentPlayer] > 0, "Defense level is already zero");
        (uint256 lastBet5, uint256 lastBet4, uint256 lastBet3, uint256 lastBet2, uint256 lastBet1) = getLastFiveBets(_gameId, _supportedPlayer);
        if (lastBet1 > lastBet2 && lastBet2 > lastBet3 && lastBet3 > lastBet4 && lastBet4 > lastBet5) {
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

     // temporarily comment out onlyContract(CONTRACT_NAME_GAMEMANAGER) until GameManager.sol is furhter defined/developed
    function startGame(
        uint256 _gameId,
        uint256 _randomRed,
        uint256 _randomBlack
        )
        public
        //onlyContract(CONTRACT_NAME_GAMEMANAGER)
    {
        setFightMap(_gameId, _randomRed, _randomBlack);
    }

    // temporarily comment out onlyContract(CONTRACT_NAME_GAMEMANAGER) until GameManager.sol is furhter defined/developed
    function bet(
        uint256 _gameId,
        uint256 _lastBetAmount,
        address _supportedPlayer,
        address _opponentPlayer,
        uint256 _randomNum)
        public
        //onlyContract(CONTRACT_NAME_GAMEMANAGER)
        returns (
            string memory attackType,
            bytes32 attackHash,
            uint256 defenseLevelOpponent
        )
    {
        uint256 index;
        (attackType, attackHash, index) = getAttackType(_gameId, _supportedPlayer, _lastBetAmount, _randomNum);
        fillBets(_gameId, _supportedPlayer, _lastBetAmount);
        defenseLevelOpponent = reduceDefenseLevel(_gameId, _supportedPlayer, _opponentPlayer);

        if (defenseLevelOpponent == 0) {
            setDirectAttacksScored(_gameId, _supportedPlayer, index);
        } else if(defenseLevelOpponent > 0 && isAttackBlocked(_gameId, _opponentPlayer)) {
            setBlockedAttacksScored(_gameId, _supportedPlayer, index);
        } else {
            setDirectAttacksScored(_gameId, _supportedPlayer, index);
        }

        setLastBetTimestamp(_gameId, _supportedPlayer, now);

    }

}
