
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

    /**
   * @dev Initialize contracts used
   * @dev Can be called only by the owner of this contract
   */
    function initialize() external onlyOwner {
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        gmGetterDB = GMGetterDB(proxy.getContract(CONTRACT_NAME_GM_GETTER_DB));
        endowmentDB = EndowmentDB(proxy.getContract(CONTRACT_NAME_ENDOWMENT_DB));
    }

    /**
     * @notice Calculates amount of Eth the winner can claim
     */
    function getWinnerShare(uint gameId, address claimer) public view returns(uint256 winningsETH, uint256 winningsKTY) {
        //TODO: check honeypot state to see if we can allow claiming
        //require(endowmentDB.getHoneypotState(gameId) == 'Claiming')

        address winningSide = gmGetterDB.getWinner(gameId);
        (uint256 betAmount, address supportedPlayer) = gmGetterDB.getBettor(gameId, claimer);

        // Is the winning player or part of the bettors of the winning corner
        require(winningSide == supportedPlayer || winningSide == claimer, "Not on the winning group");

        uint256[5] memory rates = gameVarAndFee.getDistributionRates();
 
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
        (address topBettor,) = gmGetterDB.getTopBettor(gameId, supportedPlayer);
        if (topBettor == claimer) return 1;

        // Winning SecondTop Bettor
        (address secondTopBettor,) = gmGetterDB.getSecondTopBettor(gameId, supportedPlayer);
        if (secondTopBettor == claimer) return 2;

        // Winning Other Bettors List
        if (winner == supportedPlayer) return 3;
    }


}