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
import "../../libs/SafeMath.sol";
import "../databases/GameManagerDB.sol";
import "../databases/GetterDB.sol";

contract Betting is Proxied {
    using SafeMath for uint256;

    GameManagerDB public gameManagerDB;
    GetterDB public getterDB;

    string[] attacksColumn;
    bytes32[] public hashes;

    //fight map for a game with a specific gameId
    mapping(uint256 => mapping(bytes32 => string)) public fightMap;

    // total number of direct attacks of each hitType of the given corner in a game
     mapping(uint256 => mapping(address => uint256[7])) public directAttacksScored;
     // total number of blocked attacks of each hitType of the given corner in a game
     mapping(uint256 => mapping(address => uint256[7])) public blockedAttacksScored;


    mapping(uint256 => mapping(address => uint256[])) public bets;

    function initialize() external onlyOwner {
        gameManagerDB = GameManagerDB(proxy.getContract(CONTRACT_NAME_GAMEMANAGER_DB));
        getterDB = GetterDB(proxy.getContract(CONTRACT_NAME_GETTER_DB));
        //hitsResolve = HitsResolve(proxy.getContract(CONTRACT_NAME_HITSRESOLVE));
    }

    function setAttacksColumn() public {
        attacksColumn[0] = "lowPunch";
        attacksColumn[1] = "lowKick";
        attacksColumn[2] = "lowThunder";
        attacksColumn[3] = "hardPunch";
        attacksColumn[4] = "hardKick";
        attacksColumn[5] = "hardThunder";
        attacksColumn[6] = "slash";
    }

   
    function setFightMap(uint256 _gameId, uint256 _randomRed, uint256 _randomBlack) public {
        uint randomNum = _randomRed + _randomBlack;
        bytes32 hashLowPunch = keccak256(abi.encodePacked(randomNum, "lowPunch"));
        bytes32 hashLowKick = keccak256(abi.encodePacked(randomNum, "lowKick"));
        bytes32 hashLowThunder = keccak256(abi.encodePacked(randomNum, "lowThunder"));
        bytes32 hashHardPunch = keccak256(abi.encodePacked(randomNum, "hardPunch"));
        bytes32 hashHardKick = keccak256(abi.encodePacked(randomNum, "hardKick"));
        bytes32 hashHardThunder = keccak256(abi.encodePacked(randomNum, "hardThunder"));
        bytes32 hashSlash = keccak256(abi.encodePacked(randomNum, "slash"));
        hashes.push(hashLowPunch);
        hashes.push(hashLowKick);
        hashes.push(hashLowThunder);
        hashes.push(hashHardPunch);
        hashes.push(hashHardKick);
        hashes.push(hashHardThunder);
        hashes.push(hashSlash);
        fightMap[_gameId][hashLowPunch] = "lowPunch";
        fightMap[_gameId][hashLowKick] = "lowKick";
        fightMap[_gameId][hashLowThunder] = "lowThunder";
        fightMap[_gameId][hashHardPunch] = "hardPunch";
        fightMap[_gameId][hashHardKick] = "hardKick";
        fightMap[_gameId][hashHardThunder] = "hardThunder";
        fightMap[_gameId][hashSlash] = "slash";
    }

     // set the total number of direct attacks of each hitType of the given corner in a game
    function setDirectAttacksScored(
          uint256 _gameId, 
          address _supportedPlayer,
          uint256 index
          ) 
          public {
            directAttacksScored[_gameId][_supportedPlayer][index] += 1;
          }

      // set the total number of blocked attacks of each hitType of the given corner in a game
    function setBlockedAttacksScored(
          uint256 _gameId, 
          address _supportedPlayer, 
          uint256 index
          ) 
          public {
            blockedAttacksScored[_gameId][_supportedPlayer][index] += 1;
          }
      
      // get the total number of direct attacks of each hitType of the given corner in a game
    function getDirectAttacksScored(uint256 _gameId, address _supportedPlayer) 
        public 
        view 
        returns(
            //uint256 totalLowPunch,
            //uint256 totalLowKick,
            //uint256 totalLowThunder,
            //uint256 totalHardPunch,
            //uint256 totalHardKick,
            //uint256 totalHardThunder,
            //uint256 totalSlash
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
              //uint256 totalLowPunch,
              //uint256 totalLowKick,
              //uint256 totalLowThunder,
              //uint256 totalHardPunch,
              //uint256 totalHardKick,
              //uint256 totalHardThunder,
              //uint256 totalSlash
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

    function fillBets(uint256 _gameId, address _supportedPlayer, uint256 _betAmount) public {
      bets[_gameId][_supportedPlayer].push(_betAmount);
    }

    // get last 5 bet amount of the given corner
    function getLastFiveBets(uint256 _gameId, address _supportedPlayer) 
        public 
        view 
        returns(uint lastBet1, uint lastBet2, uint lastBet3, uint lastBet4, uint lastBet5) 
    {
      uint256 arrLength = bets[_gameId][_supportedPlayer].length;
      lastBet1 = bets[_gameId][_supportedPlayer][arrLength - 5];
      lastBet2 = bets[_gameId][_supportedPlayer][arrLength - 4];
      lastBet3 = bets[_gameId][_supportedPlayer][arrLength - 3];
      lastBet4 = bets[_gameId][_supportedPlayer][arrLength - 2];
      lastBet5 = bets[_gameId][_supportedPlayer][arrLength - 1];
  }

    function startGame(uint256 _gameId, uint256 _randomRed, uint256 _randomBlack) public {
        // simple random number combination, hashed with Fight moves string names
        // sequentially generate and then return list of 7 fight moves in key-value hash map
        setFightMap(_gameId, _randomRed, _randomBlack);

    }

    function getAttackType(
        uint256 _gameId, 
        address _supportedPlayer, 
        uint256 _lastBetAmount,
        uint256 _randomNum) 
        public
        returns (
            string memory attackType,
            uint256 index
        ){
        uint256 lastBetAmount = _lastBetAmount;
        (uint256 prevBetAmount,) = getterDB.getLastBet(_gameId, _supportedPlayer);
        // lower ether than previous bet? one attack is chosen randomly from lowAttacksColumn
        if (lastBetAmount <= prevBetAmount) {
            uint256 diceLowValues = randomGen(_randomNum);
            if (diceLowValues <= 33) {
                attackType = attacksColumn[0];
                index = 0;
            } else if (diceLowValues <= 66 && diceLowValues > 33) {
                attackType = attacksColumn[1];
                index = 1;
            } else if (diceLowValues > 66) {
                attackType = attacksColumn[2];
                index = 2;
            }
        } else if (lastBetAmount > prevBetAmount) { 
             // higher ether than previous bet? one attack is chosen randomly from highAttacksColumn
            uint256 diceHardValues = randomGen(_randomNum);
            if (diceHardValues <= 25) {
                attackType = attacksColumn[3];
                index = 3;
            } else if (diceHardValues > 25 && diceHardValues <= 50) {
                attackType = attacksColumn[4];
                index = 4;
            } else if (diceHardValues > 50 && diceHardValues <= 75) {
                attackType = attacksColumn[5];
                index = 5;
            } else if (diceHardValues > 75) {
                attackType = attacksColumn[6];
                index = 6;
            }
        }

    }

    // determine whether the attack type is blocked or direct 
    function isAttackBlocked(uint256 _gameId, address _opponentPlayer) public returns(bool isBlocked) {
        // get the last bet timestamp of the given corner
        (,uint256 lastBetTimestamp) = getterDB.getLastBet(_gameId, _opponentPlayer);
        if (lastBetTimestamp < now.sub(5)) {
            isBlocked = true;
        } else if(lastBetTimestamp >= now.sub(5)) {
            isBlocked = false;
        }
    }

     // the defense level of an oppoent is reduced each time 
     // a bet is received from attacker and the last five bets are compared on the condition to see 
     // if each bet was bigger than the previous bet in progression.
     function reduceDefenseLevel(
        uint256 _gameId, 
        address _supportedPlayer,
        address _opponentPlayer
        ) 
        public
        returns (uint)
        {
        uint256 defenseLevel = getterDB.getDefenseLevel(_gameId, _opponentPlayer);
        // getLast5Bets() is yet to be implemented in getterDB. 
        // Will make modifications in function name if necessary once it is implemented.
        (uint256 lastBet5, uint256 lastBet4, uint256 lastBet3, uint256 lastBet2, uint256 lastBet1) = getLastFiveBets(_gameId, _supportedPlayer);
        if (lastBet1 > lastBet2 && lastBet2 > lastBet3 && lastBet3 > lastBet4 && lastBet4 > lastBet5) {
            defenseLevel.sub(1);
        }
        return defenseLevel;
    }

    function Bet(
        uint256 _gameId,
        uint256 _lastBetAmount,
        address _supportedPlayer,
        address _opponentPlayer,
        uint256 _randomNum)
        public
        returns (
            string memory attackType,
            uint256 index,
            bytes32 attackHash,
            uint256 defenseLevelOpponent
        )
    {
        fillBets(_gameId, _supportedPlayer, _lastBetAmount);
        (attackType, index) = getAttackType(_gameId, _supportedPlayer, _lastBetAmount, _randomNum);
        attackHash = hashes[index];
        defenseLevelOpponent = reduceDefenseLevel(_gameId, _supportedPlayer, _opponentPlayer);

        if (defenseLevelOpponent == 0) {
            setDirectAttacksScored(_gameId, _supportedPlayer, index);
        } else if(defenseLevelOpponent > 0 && isAttackBlocked(_gameId, _opponentPlayer)) {
            setBlockedAttacksScored(_gameId, _supportedPlayer, index);
        } else {
            setDirectAttacksScored(_gameId, _supportedPlayer, index);
        }
    }


     

    /**
     * @author @ziweidream
     * @notice generates a random number from 0 to 100 based on the last block hash, blocktime, block difficulty, and seed
     * @return The random number generated
     */
    function randomGen(uint256 seed) public view returns (uint256 randomNumber) {
        seed++;
        randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number-1), block.timestamp, block.difficulty, seed)))%100;
    }
}
