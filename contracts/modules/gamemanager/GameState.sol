pragma solidity ^0.5.5;

import '../proxy/Proxied.sol';

contract GameManager is Proxied {

    // enum eGameState {WAITING, PRE_GAME, MAIN_GAME, KITTIE_HELL, WITHDREW_EARNINGS, CANCELLED}
    // enum eCorner {BLACK, RED}
    // enum eCatOutfit {KIMONO, PANTHER}
    // enum eCatBelt {BLACK, WHITE, YELLOW, RED}

    // event NewGame(uint gameId, address playerRed, uint kittieRed, address playerBlack, uint kittieBlack, uint gameStartTime);
    // event NewSupporter(uint game_id, address supporter, address playerSupported);
    // event PressStart(uint game_id, address player);
    // event NewBet(uint game_id, address player, uint corner, uint ethAmount);
    // event GameStateChanged(uint game_id, eGameState old_state, eGameState new_state);

    // struct GameDetails {
    //     eGameState  state;

    //     address playerRed;
    //     address playerBlack;
    //     uint kittyRed;
    //     uint kittyBlack;
        
    //     uint listingFee;
    //     uint ticketFee;
    //     uint bettingFee;
    //     uint min_required_supporters;

    //     uint time_game_created;
    //     uint time_pre_game;
    //     uint time_main_game;
    //     uint time_game_over;
    //     uint time_kittiehell_over;

    //     address winner;
    // }

    // struct Supporter {
    //     address supportedPlayer;
    //     bool paid_ticket_fee;
    //     uint bets_total_eth;
    //     uint last_bet_eth;
    //     bool withdrew_reward;
    // }

    // struct Corner {
    //     bool pressedStart;
    //     uint num_supporters;
    //     uint randomNum; //when pressing start
    //     address topBettor;
    //     address secondTopBettor;
    //     uint amountTopBettor;
    //     uint amountSecondTopBettor;
    //     uint totalEth;
    // }

    // mapping(uint => GameDetails) public games;
    // mapping(uint => mapping(address => Corner)) gameByAddress;
    // mapping(uint => mapping(address => Supporter)) supporterByAddress;


    // function newGame
    // (   uint gameId, address playerRed, address playerBlack,
    //     uint256 kittyRed, uint256 kittyBlack,
    //     uint gameStartTime
    // )
    //     external
    //     onlyContract(CONTRACT_NAME_GAMEMANAGER)
    // {
    //     GameDetails memory _game;
    //     _game.playerRed = playerRed;
    //     _game.playerBlack = playerBlack;
    //     _game.kittyRed = kittyRed;
    //     _game.kittyBlack = kittyBlack;
    //     _game.time_main_game = gameStartTime;

    //     games[gameId] = _game;

    //     emit NewGame(gameId, playerRed, kittyRed, playerBlack, kittyBlack, gameStartTime);
    // }

    // function hitStart(uint gameId, address player) external onlyContract(CONTRACT_NAME_GAMEMANAGER){
    //     gameByAddress[gameId][player].pressedStart = true;
    // }

    // function setRandom(uint gameId, address player, uint randomNum) external onlyContract(CONTRACT_NAME_GAMEMANAGER){
    //     gameByAddress[gameId][player].randomNum = randomNum;
    // }

}