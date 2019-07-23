pragma solidity ^0.5.5;

import '../proxy/Proxied.sol';

contract GameStore is Proxied {

    struct Game {
        uint randomNum; //when pressing start
        bool pressedStart;
        address topBettor;
        address secondTopBettor;
    }

    mapping(uint => mapping(address => Game)) gameByPlayer;


    function hitStart(uint gameId, address player) external onlyContract(CONTRACT_NAME_GAMEMANAGER){
        gameByPlayer[gameId][player].pressedStart = true;
    }

    function didHitStart(uint gameId, address player) public view returns(bool){
        return gameByPlayer[gameId][player].pressedStart;
    }

    function setRandom(uint gameId, address player, uint randomNum) external onlyContract(CONTRACT_NAME_GAMEMANAGER){
        gameByPlayer[gameId][player].randomNum = randomNum;
    }

    function getRandom(uint gameId, address player) public view returns(uint){
        return gameByPlayer[gameId][player].randomNum;
    }

    function updateTopBettor(uint gameId, address player, address newTopBettor) external onlyContract(CONTRACT_NAME_GAMEMANAGER){
        gameByPlayer[gameId][player].topBettor = newTopBettor;
    }

    function getTopBettor(uint gameId, address player) public view returns(address){
        return gameByPlayer[gameId][player].topBettor;
    }

    function updateSecondTopBettor(uint gameId, address player, address newSecondTopBettor) external onlyContract(CONTRACT_NAME_GAMEMANAGER){
        gameByPlayer[gameId][player].secondTopBettor = newSecondTopBettor;
    }

    function getSecondTopBettor(uint gameId, address player) public view returns(address){
        return gameByPlayer[gameId][player].secondTopBettor;
    }
}