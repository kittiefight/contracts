
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
import '../databases/GameManagerDB.sol';
// import "../databases/EndowmentDB.sol";

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
    GameManagerDB public gameManagerDB;
    // EndowmentDB public endowmentDB;

    /**
   * @dev Initialize contracts used
   * @dev Can be called only by the owner of this contract
   */
    function initialize() external onlyOwner {
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        gameManagerDB = GameManagerDB(proxy.getContract(CONTRACT_NAME_GAMEMANAGER_DB));
        // endowmentDB = EndowmentDB(proxy.getContract(CONTRACT_NAME_ENDOWMENT_DB));
    }

    /**
     * @notice Calculates amount of Eth the winner can claim
     */
    function getWinnerShare(uint gameId, address claimer) public view returns(uint winningsETH, uint winningsKTY) {

        //address winningSide = gameManagerDB.getWinner(gameId);
        //(,address supportedPlayer) = gameManagerDB.getBettor(gameId, claimer);

        // Is the winning player or part of the bettors of the winning corner
        //require(winningSide == supportedPlayer || winningSide == claimer, "Not on the winning group");

        uint256[5] memory rates = gameVarAndFee.getDistributionRates();

        //TEMPORAL
        address winningSide = address(0);
        address supportedPlayer = address(0);

        uint256 winningCategory = checkWinnerCategory(gameId, claimer, winningSide, supportedPlayer);

        // uint256 totalEthFunds = endowmentDB.getHoneypotTotalETH(gameId);
        // uint256 totalKTYFunds = endowmentDB.getHoneypotTotalKTY(gameId);

        uint256 totalEthFunds = 100;
        uint256 totalKTYFunds = 25000;

        if (winningCategory < 4) {
            if (winningCategory == 3){
                //get other supporters count

                //get other supporters totalBets

                // TODO: distribute the 20% of the jackpot according to %
                // depending of each bettor's bet and total bets of other bettors
                //return ((totalEthFunds.mul(rates[winningCategory])).div(100)).div(otherBettorsCount);
            }
            winningsETH = (totalEthFunds.mul(rates[winningCategory])).div(100);
            winningsKTY = (totalKTYFunds.mul(rates[winningCategory])).div(100);
        }

        return (0, 0);
    }

    function checkWinnerCategory
    (
        uint gameId, address claimer,
        address winner,  address supportedPlayer
    )
        internal pure
        returns(uint winningGroup)
    {
        // Winning Player
        // if (claimer == winner) return 0;

        // Winning Top Bettor
        // if (gameManagerDB.getTopBettor(gameId) == claimer) return 1;

        // Winning SecondTop Bettor
        // if (gameManagerDB.getSecondTopBettor(gameId) == claimer) return 2;

        // Winning Other Bettors List
        //(,address supportedPlayer) = gameManagerDB.getBettor(gameId, claimer);
        // if (winner == supportedPlayer) return 3;

        // Else
        return 100;
    }


}