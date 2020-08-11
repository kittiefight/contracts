pragma solidity ^0.5.5;

import '../proxy/Proxied.sol';
import '../../authority/Guard.sol';
import "../../libs/SafeMath.sol";
import "../../GameVarAndFee.sol";
import "../databases/GenericDB.sol";
import "../databases/GMGetterDB.sol";


contract GameManagerHelper is Proxied, Guard {
    using SafeMath for uint256;

    //Contract Variables
    GenericDB public genericDB;
    GMGetterDB public gmGetterDB;
    GameVarAndFee public gameVarAndFee;

    /**
    * @dev Sets related contracts
    * @dev Can be called only by the owner of this contract
    */
    function initialize() external onlyOwner {
        genericDB = GenericDB(proxy.getContract(CONTRACT_NAME_GENERIC_DB));
        gmGetterDB = GMGetterDB(proxy.getContract(CONTRACT_NAME_GM_GETTER_DB));
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
    }

    function checkPerformanceHelper(uint gameId, uint gameEndTime) external view returns(bool){
        //each time 1 minute before game ends
        uint performanceTimeCheck = gameVarAndFee.getPerformanceTimeCheck();
        
        if(gameEndTime.sub(performanceTimeCheck) <= now) {
            //get initial jackpot, need endowment to send this when creating honeypot
            (,,uint initialEth, uint currentJackpotEth,,,) = gmGetterDB.getHoneypotInfo(gameId);

            if(currentJackpotEth < initialEth.mul(10)) return true;
            return false;
        }
    }

    /**
     * @dev Update kittie playing game Id
     */
    function updateKittiesGame(uint kittyBlack, uint kittyRed, uint gameId)
        external
        onlyContract(CONTRACT_NAME_GAMECREATION)
    {
        genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_HELPER, keccak256(abi.encodePacked(kittyBlack, "playingGame")), gameId);
        genericDB.setUintStorage(CONTRACT_NAME_GAMEMANAGER_HELPER, keccak256(abi.encodePacked(kittyRed, "playingGame")), gameId);
    }
}