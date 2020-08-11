pragma solidity ^0.5.5;

import '../proxy/Proxied.sol';
import '../../authority/Guard.sol';
import "../../libs/SafeMath.sol";
import "../../GameVarAndFee.sol";
import "../databases/GenericDB.sol";
import "../databases/GMGetterDB.sol";
import "../endowment/EndowmentFund.sol";
import "../databases/EndowmentDB.sol";


contract GameManagerHelper is Proxied, Guard {
    using SafeMath for uint256;

    //Contract Variables
    GenericDB public genericDB;
    GMGetterDB public gmGetterDB;
    GameVarAndFee public gameVarAndFee;
    EndowmentDB public endowmentDB;
    EndowmentFund public endowmentFund;

    enum HoneypotState {
        created,
        assigned,
        gameScheduled,
        gameStarted,
        forefeited,
        claiming,
        dissolved
    }

    /**
    * @dev Sets related contracts
    * @dev Can be called only by the owner of this contract
    */
    function initialize() external onlyOwner {
        genericDB = GenericDB(proxy.getContract(CONTRACT_NAME_GENERIC_DB));
        gmGetterDB = GMGetterDB(proxy.getContract(CONTRACT_NAME_GM_GETTER_DB));
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        endowmentDB = EndowmentDB(proxy.getContract(CONTRACT_NAME_ENDOWMENT_DB));
        endowmentFund = EndowmentFund(proxy.getContract(CONTRACT_NAME_ENDOWMENT_FUND));
    }

    /**
    * @dev updateHoneyPotState
    */
    function updateHoneyPotState(uint256 _gameId, uint _state) public onlyContract(CONTRACT_NAME_GAMEMANAGER) {
        uint256 claimTime;
        if (_state == uint(HoneypotState.claiming)){
            //Send immediately initialEth+15%oflosing and 15%ofKTY to endowment
            (uint256 winningsETH, uint256 winningsKTY) = endowmentFund.getEndowmentShare(_gameId);
            endowmentDB.updateEndowmentFund(winningsKTY, winningsETH, false);
            endowmentDB.updateHoneyPotFund(_gameId, winningsKTY, winningsETH, true);
        }
        if(_state == uint(HoneypotState.forefeited)) {
            (uint256 eth, uint256 kty) = endowmentDB.getHoneypotTotal(_gameId);
            endowmentDB.updateEndowmentFund(kty, eth, false);
            endowmentDB.updateHoneyPotFund(_gameId, kty, eth, true);
        }
        endowmentDB.setHoneypotState(_gameId, _state);
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