
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
// import "../../CronJob.sol";

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
        gmGetterDB = GMGetterDB(proxy.getContract(CONTRACT_NAME_GM_GETTER_DB));
    }

    /**
     * @notice Calculates amount of Eth the winner can claim
     */
    function getWinnerShare(uint256 gameId, address payable claimer)
        public view
        returns(uint256 winningsETH, uint256 winningsKTY)
    {
        (address winner, /*address loser*/, uint256 totalBetsForLosingCorner) = getWinnerLoser(gameId);

        require(winner != address(0));

        (uint256 bet, address supportedPlayer,,) = gmGetterDB.getSupporterInfo(gameId, claimer);

        // If its not the winning player or part of the bettors of the winning corner
        if(claimer != winner && supportedPlayer != winner) return (0,0);
 
        uint256 winningCategory = checkWinnerCategory(gameId, claimer, winner);

        if (claimer == winner)
            bet = gmGetterDB.getPlayerBet(gameId, claimer);

        (winningsETH, winningsKTY) = calculator(totalBetsForLosingCorner, winningCategory, bet, gameId);
    }

    function calculator(uint256 totalBetsForLosingCorner, uint256 winningCategory, uint256 bet, uint256 gameId)
        internal view
        returns(uint256, uint256)
    {
        uint256[5] memory rates = gameStore.getDistributionRates(gameId);
        (, uint256 totalKTYFunds) = gmGetterDB.getFinalHoneypot(gameId);

        uint256 winningsETH = (totalBetsForLosingCorner.mul(rates[winningCategory])).div(1000000); //1,000,000 is the percentage base
        uint256 winningsKTY = (totalKTYFunds.mul(rates[winningCategory])).div(1000000); //1,000,000 is the percentage base

        //Other bettors winnings
        if (winningCategory == 3){
            return getOtherWinnersShare(winningsKTY, winningsETH, bet, gameId);
        }
        else {
            return (bet.add(winningsETH), winningsKTY);
        }
    }

    function getOtherWinnersShare(uint256 winningsKTY, uint256 winningsETH, uint256 bet,
        uint256 gameId)
        internal view
        returns(uint256, uint256)
    {
        address[3] memory winners;
        (winners[0], winners[1], winners[2]) = gmGetterDB.getWinners(gameId);
        (uint256 betAmountTop,,,) = gmGetterDB.getSupporterInfo(gameId, winners[1]);
        (uint256 betAmountSecondTop,,,) = gmGetterDB.getSupporterInfo(gameId, winners[2]);

        //getPlayerBet
        uint256 playerBet = gmGetterDB.getPlayerBet(gameId, winners[0]);

        //get other supporters totalBets for winning side
        uint256 totalBets = gmGetterDB.getTotalBet(gameId, winners[0]);

        //Remove top and secondTop total bets
        totalBets = totalBets.sub(betAmountTop).sub(betAmountSecondTop).sub(playerBet);
        winningsETH = winningsETH.mul(bet).div(totalBets);
        winningsKTY = winningsKTY.mul(bet).div(totalBets);

        // Distribute the 20% of the jackpot according to amount that supporter bet in game
        // This is to avoid a bettor for claiming winings if he/she did not bet
        return (bet.add(winningsETH), winningsKTY);
    }


    function getEndowmentShare(uint gameId) public view returns(uint256 winningsETH, uint256 winningsKTY){
        (/*uint256 totalEthFunds*/, uint256 totalKTYFunds) = gmGetterDB.getFinalHoneypot(gameId);

        uint256[5] memory rates = gameStore.getDistributionRates(gameId);
        (,, uint initialEth,,,,) = gmGetterDB.getHoneypotInfo(gameId);

        (/*address winner*/, /*address loser*/, uint256 totalBetsForLosingCorner) = getWinnerLoser(gameId);

        winningsETH = initialEth.add(totalBetsForLosingCorner.mul(rates[4]).div(1000000)); //1,000,000 is the percentage base
        winningsKTY = (totalKTYFunds.mul(rates[4])).div(1000000); //1,000,000 is the percentage base
    }

    function checkWinnerCategory
    (
        uint gameId, address payable claimer,
        address winner
    )
        public view
        returns(uint256 winningGroup)
    {
        // Winning Player
        if (winner == claimer) return 0;

        // Winning Top Bettor
        if (gameStore.getTopBettor(gameId, winner) == claimer) return 1;

        // Winning SecondTop Bettor
        if (gameStore.getSecondTopBettor(gameId, winner) == claimer) return 2;

        // Winning Other Bettors List
        return 3;
    }

    function getWinnerLoser(uint256 gameId)
        public view
        returns(address winner, address loser, uint256 totalBetsForLosingCorner)
    {
        (winner,,) = gmGetterDB.getWinners(gameId);
        loser = gameStore.getOpponent(gameId, winner);
        totalBetsForLosingCorner = gmGetterDB.getTotalBet(gameId, loser);
    }
}