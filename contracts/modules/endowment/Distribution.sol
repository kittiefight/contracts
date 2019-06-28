
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
import '../../mocks/MockERC20Token.sol';
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
     * @notice prevent interaction if the address is not on record as one of the
     * winning groups or prevent interaction if the address has already claimed
     */
    modifier preventClaims(uint gameId) {
        //address winner = gameManagerDB.getWinner(gameId);
        //(,address supportedPlayer) = gameManagerDB.getBettor(gameId, msg.sender);
        //require(supportedPlayer == winner, "Not on the winning group");
        // require(gameManagerDB.hasRedeemed(gameId, winner), 'Winnings already claimed');
        _;
    }

    /**
     * @notice Eth and token percentage withdrawal scheme
     * Only able to be called when game is over, checks if game is over and them allows claim
     * allow address to claim share and dissallow and subsequent claimes by "modifier".
     * Triggered and calls the "sendEndowmentShare" function ONCE after the game is over.
     */
    function redeem(uint gameId) public preventClaims(gameId) {

        //uint sharesETH = getWinnerShare(gameId, msg.sender);

        //TODO: send ether to adddress?

        // sendEndowmentShare(); // is it needed?
    }

    /**
     * @notice Calculates amount of Eth the winner can claim
     */
    function getWinnerShare(uint gameId, address winner) public view returns(uint) {
        uint256[5] memory rates = gameVarAndFee.getDistributionRates();

        uint256 winningCategory = checkWinnerCategory(gameId, winner);

        // uint256 totalEthFunds = endowmentDB.getHoneypotTotalETH(gameId); //Or where is the total jackpot stored?
        uint256 totalEthFunds = 1000;

        if (winningCategory < 4) {
            if (winningCategory == 3){
                //get other supporters count
                //return ((totalEthFunds.mul(rates[winningCategory])).div(100)).div(otherBettorsCount);
            }
            return (totalEthFunds.mul(rates[winningCategory])).div(100);
        }
        return 0;
    }

    function checkWinnerCategory(uint gameId, address winner) internal pure returns(uint winningGroup) {
        //address winningSide = gameManagerDB.getWinner(gameId);
        // Not yet implemented in Game Manager DB
        // if (winningSide == winner) return 0;
        // if (gameManagerDB.getTopBettor(gameId) == winner) return 1;
        // if (gameManagerDB.getSecondTopBettor(gameId) == winner) return 2;

        //(,address supportedPlayer) = gameManagerDB.getBettor(gameId, winner);
        // if (winningSide == supportedPlayer) return 3;
        return 100;
    }


}