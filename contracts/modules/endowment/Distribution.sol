
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


import '../../GameVarAndFee.sol';
import '../proxy/Proxied.sol';
import '../../libs/SafeMath.sol';
import '../databases/GMGetterDB.sol';
import "../databases/EndowmentDB.sol";
import "../../interfaces/ERC20Standard.sol";
import "./Escrow.sol";
import "../gamemanager/GameStore.sol";

/**
 * @title Distribution Contract
 * @dev The distribution contract allows the endowmentfund contract to properly distribute
 * Eth and KTY tokens funds, from each games honeypot to all winners in a game according
 * to the scheduled percentage.
 * @author @wafflemakr @hamaad
 */
contract Distribution is Proxied {

    using SafeMath for uint256;

    GameVarAndFee public gameVarAndFee;
    GMGetterDB public gmGetterDB;
    EndowmentDB public endowmentDB;
    ERC20Standard public kittieFightToken;
    GameStore public gameStore;

    /**
    * @dev Sets related contracts
    * @dev Can be called only by the owner of this contract
    */
    function initialize() external onlyOwner {
        endowmentDB = EndowmentDB(proxy.getContract(CONTRACT_NAME_ENDOWMENT_DB));
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        kittieFightToken = ERC20Standard(proxy.getContract(CONTRACT_NAME_KITTIEFIGHTOKEN));
        gameStore = GameStore(proxy.getContract(CONTRACT_NAME_GAMESTORE));
    }

    /**
     * @notice Calculates amount of Eth the winner can claim
     */
    function getWinnerShare(uint gameId, address claimer) public view returns(uint256 winningsETH, uint256 winningsKTY) {

        (address winningSide,,) = gmGetterDB.getWinners(gameId);

        require(winningSide != address(0), 'No winner detected for this game');

        (uint256 betAmount, address supportedPlayer,) = gmGetterDB.getSupporterInfo(gameId, claimer);

        // Is the winning player or part of the bettors of the winning corner
        require(winningSide == supportedPlayer || winningSide == claimer, "Not on the winning group");

        uint256[5] memory rates = gameStore.getDistributionRates(gameId);
 
        uint8 winningCategory = checkWinnerCategory(gameId, claimer, winningSide, supportedPlayer);

        uint256 totalEthFunds = endowmentDB.getHoneypotTotalETH(gameId);
        uint256 totalKTYFunds = endowmentDB.getHoneypotTotalKTY(gameId);
        
        winningsETH = (totalEthFunds.mul(rates[winningCategory])).div(100);
        winningsKTY = (totalKTYFunds.mul(rates[winningCategory])).div(100);

        //Other bettors winnings
        if (winningCategory == 3){
            // uint amountSupporters = gmGetterDB.getSupporters(gameId, winningSide);

            //get other supporters totalBets for winning side
            uint256 totalBets = gmGetterDB.getTotalBet(gameId, winningSide);

            // Distribute the 20% of the jackpot according to amount that supporter bet in game
            // This is to avoid a bettor for claiming winings if he/she did not bet
            winningsETH = winningsETH.mul(betAmount).div(totalBets);
            winningsKTY = winningsKTY.mul(betAmount).div(totalBets);
        }
    }

    function getEndowmentShare(uint gameId) public view returns(uint256 winningsETH, uint256 winningsKTY){
        uint256 totalEthFunds = endowmentDB.getHoneypotTotalETH(gameId);
        uint256 totalKTYFunds = endowmentDB.getHoneypotTotalKTY(gameId);

        uint256[5] memory rates = gameStore.getDistributionRates(gameId);
        
        winningsETH = (totalEthFunds.mul(rates[4])).div(100);
        winningsKTY = (totalKTYFunds.mul(rates[4])).div(100);
    }

    function checkWinnerCategory
    (
        uint gameId, address claimer,
        address winner, address supportedPlayer
    )
        public view
        returns(uint8 winningGroup)
    {
        // Winning Player
        if (winner == claimer) return 0;

        // Winning Top Bettor
        if (gameStore.getTopBettor(gameId, supportedPlayer) == claimer) return 1;

        // Winning SecondTop Bettor
        if (gameStore.getSecondTopBettor(gameId, supportedPlayer) == claimer) return 2;

        // Winning Other Bettors List
        if (winner == supportedPlayer) return 3;
    }


}