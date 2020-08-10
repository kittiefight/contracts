pragma solidity ^0.5.5;

import '../proxy/Proxied.sol';
import '../../authority/Guard.sol';
import "../../libs/SafeMath.sol";
import "../../GameVarAndFee.sol";
import "../databases/GMGetterDB.sol";

contract GameManagerHelper is Proxied, Guard {
    using SafeMath for uint256;

    //Contract Variables
    GMGetterDB public gmGetterDB;
    GameVarAndFee public gameVarAndFee;

    /**
    * @dev Sets related contracts
    * @dev Can be called only by the owner of this contract
    */
    function initialize() external onlyOwner {
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
}