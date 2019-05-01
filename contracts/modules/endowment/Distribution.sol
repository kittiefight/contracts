
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

/**
 * @title Distribution Contract
 * @dev The distribution contract allows the endowmentfund contract to properly distribute 
 * Eth and KTY tokens funds, from each games honeypot to all winners in a game according 
 * to the scheduled percentage.
 * @author @wafflemakr @hamaad
 */
contract Distribution is Proxied {

    struct DistributionStatus {  

        uint totalContributionInETH;
        uint totalContributionInKTY;
        mapping (address => uint) winnerPercentage;
        mapping (address => uint) topContributorPercentage;
        mapping (address => uint) top2ndContributorPercentage;
        mapping (address => uint) winningGroupPercentage;
        mapping (address => uint) endowmentSharePercentage;
    }

    struct Percentages {

        uint percentShareInETH;
        uint percentShareInKTY;
        uint EthtoClaim;
        uint KTYtoClaim;
        uint contributionsETH;
        uint contributionsKTY;
    }

    // Distribution Status by HoneyPotId
    mapping (uint => DistributionStatus) public distributionById;

    mapping (address => Percentages) public percentagesByAddress;


    /**
     * @notice prevent interaction if the address is not on record as one of the 
     * winning groups or prevent interaction if the address has already claimed
     */
    modifier preventClaims {
        _;
    }

    /**
     * @notice Calculates amount of Eth and KTY token by percentage  of requesting winner
     */
    function calculateAmountByPercentage() public {

    }

    /**
     * @notice Updates winner address
     */
    function updateWinner(address _winner, uint _honeyPotId) public returns(uint){

        // TODO: define how to return rates from GameVarAndFee contract
        uint[] memory rates = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE)).getDistributionRates();
        distributionById[_honeyPotId].winnerPercentage[_winner] = rates[0];
        return rates[0];
    }

    /**
     * @notice Updates highest ETH contributor address
     */
    function updateTopContributor(address _top, uint _honeyPotId) public {

    }

    /**
     * @notice Updates second highest ETH contributor address
     */
    function updateSecondTopContributor(address _secondTop, uint _honeyPotId) public {

    }

    /**
     * @notice Returns bool wheather address has claimed winning shares in KTY and ETH
     */
    function hasRedeemed() internal view returns(bool){

    }

    /**
     * @notice Eth and token percentage withdrawal scheme
     * Only able to be called when game is over, checks if game is over and them allows claim
     * allow address to claim share and dissallow and subsequent claimes by "modifier".
     * Triggered and calls the "sendEndowmentShare" function ONCE after the game is over.
     */
    function redeem() public preventClaims {

    }

    /**
     * @notice Triggered and called ONCE, by "redeem" function to allow send of endowment 
     * fund share game Honeypot/jackpot funds of Eth and tokens.
     */
    function sendEndowmentShare () internal {

    }

  

}