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
import "./HitsResolveAlgo.sol";

contract Betting is Proxied {
    using SafeMath for uint256;

    GameManagerDB public gameManagerDB;
    GetterDB public getterDB;
    HitsResolve public hitsResolve;


    // Game states are already defined in GameManager.sol;
    //uint256 public constant GAME_STATE_SUCCESS = 1;
    //uint256 public constant GAME_STATE_WAITING = 2;
    //uint256 public constant GAME_STATE_FORFEIT = 3;

    struct AttacksList {
        uint256 lowPunch;
        uint256 lowKick;
        uint256 lowThunder;
        uint256 hardPunch;
        uint256 hardkick;
        uint256 hardThunder;
        uint256 slash;
    }

    AttacksList FinalAttackValues;

    string[] lowAttacksColumn;
    string[] hardAttacksColumn;

    // to be determined: how to calculate the score? 
    // maybe the scores should be stored in GameManagerDB instead of here
    uint256[] blockedAttacksScoredBlackCorner;
    uint256[] directdAttacksScoredBlackCorner;
    uint256[] blockedAttacksScoredRedCorner;
    uint256[] directAttacksScoredRedCorner;

    // LastBet is stored in GameManagerDB already, so the four variables below are not necessary any more.
    // uint256 lastEthBetAmountBlackCorner;
    //uint256 lastAttackTimeBlackCorner;
    //uint256 lastEthBetAmountRedCorner;
    //uint256 lastAttackTimeRedCorner;

    mapping(bytes32 => string) public fightMap;

    // direct attacks: to be discussed and determined
    mapping(uint256 => mapping(address => uint256[])) public directAttacksScores;

    function initialize() external onlyOwner {
        gameManagerDB = gameManagerDB(proxy.getContract(CONTRACT_NAME_GAMEMANAGER_DB));
        getterDB = GetterDB(proxy.getContract(CONTRACT_NAME_GETTER_DB));
        hitsResolve = HitsResolve(proxy.getContract(CONTRACT_NAME_HITSRESOLVE));
    }

    function setAttacksColumn() public {
        lowAttacksColumn[0] = "lowPunch";
        lowAttacksColumn[1] = "lowKick";
        lowAttacksColumn[2] = "lowThunder";
        hardAttacksColumn[0] = "hardPunch";
        hardAttacksColumn[1] = "hardKick";
        hardAttacksColumn[2] = "hardThunder";
        hardAttacksColumn[3] = "slash";
    }

   
    function setFightMap(uint256 _randomRed, uint256 _randomBlack) public {
        uint randomNum = _randomRed.add(_randomBlack);
        bytes32 hashLowPunch = keccak256(abi.encodePacked(randomNum, "lowPunch"));
        bytes32 hashLowKick = keccak256(abi.encodePacked(randomNum, "lowKick"));
        bytes32 hashLowThunder = keccak256(abi.encodePacked(randomNum, "lowThunder"));
        bytes32 hashHardPunch = keccak256(abi.encodePacked(randomNum, "hardPunch"));
        bytes32 hashHardKick = keccak256(abi.encodePacked(randomNum, "hardKick"));
        bytes32 hashHardThunder = keccak256(abi.encodePacked(randomNum, "hardThunder"));
        bytes32 hashSlash = keccak256(abi.encodePacked(randomNum, "slash"));
        fightMap[hashLowPunch] = "lowPunch";
        fightMap[hashLowKick] = "lowKick";
        fightMap[hashLowThunder] = "lowThunder";
        fightMap[hashHardPunch] = "hardPunch";
        fightMap[hashHardKick] = "hardKick";
        fightMap[hashHardThunder] = "hardThunder";
        fightMap[hashSlash] = "slash";
    }

    function startGame(uint256 _randomRed, uint256 _randomBlack) public returns (uint gameStarted) {
        // simple random number combination, hashed with Fight moves string names
        // sequentially generate and then return list of 7 fight moves in key-value hash map
        setFightMap(_randomRed, _randomBlack);

    }

    function storeRandomSeed(uint256 _gameID, uint256 _playerBet) internal returns (uint256 currentRandom) {
        // calls CalculateCurrentRandom() in hitResolver to store and calculate currentRandom
        hitsResolve.calculateCurrentRandom(_gameID, _playerBet);
    }

    function getAttackType(
        uint256 _gameId, 
        address _supportedPlayer, 
        uint256 _randomNum) 
        internal
        payable 
        returns (
            string memory attackType
        ){
        uint256 lastBetAmount = msg.value;
        uint256 prevBetAmount = getterDB.getLastBet(_gameId, _supportedPlayer);
        // lower ether than previous bet? one attack is chosen randomly from lowAttacksColumn
        if (lastBetAmount <= prevBetAmount) {
            uint256 diceLowValues = randomGen(_randomNum);
            if (diceLowValues <= 33) {
                attackType = lowAttacksColumn[0];
            } else if (diceLowValues <= 66 && diceLowValues > 33) {
                attackType = lowAttacksColumn[1];
            } else if (diceLowValues > 66) {
                attackType = lowAttacksColumn[2];
            }
        } else if (lastBetAmount > prevBetAmount) { 
             // higher ether than previous bet? one attack is chosen randomly from highAttacksColumn
            uint256 diceHardValues = randomGen(_randomNum);
            if (diceHardValues <= 25) {
                attackType = hardAttacksColumn[0];
            } else if (diceHardValues > 25 && diceHardValues <= 50) {
                attackType = hardAttacksColumn[1];
            } else if (diceHardValues > 50 && diceHardValues <= 75) {
                attackType = hardAttacksColumn[2];
            } else if (diceHardValues > 75) {
                attackType = hardAttacksColumn[3];
            }
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
        internal
        payable 
        returns (uint)
        {
        uint256 lastBetAmount = msg.value;
        uint256 defenseLevel = getterDB.getDefenseLevel(_gameId, _opponentPlayer);
        // getLast5Bets() is yet to be implemented in getterDB. 
        // Will make modifications in function name if necessary once it is implemented.
        (uint256 lastBet4, uint256 lastBet3, uint256 lastBet2, uint256 lastBet1) = getterDB.getLast5Bets(_gameId, _supportedPlayer);
        if (lastBetAmount > lastBet1 && lastBet1 > lastBet2 && lastBet2 > lastBet3 && lastBet3 > lastBet4) {
            defenseLevel.sub(1);
        }
        return defenseLevel;
    }

     // calls endowment api : send KTY token fee to endowment fund 
     // this function already exists in GameManager.sol
     function payBettingFee() internal {
         endowmentFund.contributeKFT(gameId, account, gameVarAndFee.getBettingFee());
    }

    function Bet(
        uint256 _gameId, 
        address _supportedPlayer, 
        address _opponentPlayer,
        uint256 _randomNum) 
        public 
        payable 
        returns (
            string memory attackType,
            uint256 defenseLevelOpponent
        )
    {
        // storeRandomSeed() is already called in GameManager.sol: bet()
        // storeRandomSeed(_gameId, _randomNum);
        attackType = getAttackType(_gameId, _supportedPlayer, _randomNum);
        defenseLevelOpponent = reduceDefenseLevel(_gameId, _supportedPlayer, _opponentPlayer);
        // paybettingfee() is already called by GaeManager.sol: bet()
    }

     function funcitonToFinalizeGame() public {
        // finalizeGame() returns 7 values
        // (uint256 lowPunch, uint256 lowKick, uint256 lowThunder, uint256 hardPunch,
        // uint256 hardKick, uint256 hardThunder, uint256 slash) = hitsResolve.finalizeHitTypeValues(gameId, randomNum);


        // the values are then used to calculate exact number of points
        // formula to be discussed and derived 
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
