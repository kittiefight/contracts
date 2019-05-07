
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
import '../kittieHELL/KittieFIGHTToken.sol';

/**
 * @title Distribution Contract
 * @dev The distribution contract allows the endowmentfund contract to properly distribute
 * Eth and KTY tokens funds, from each games honeypot to all winners in a game according
 * to the scheduled percentage.
 * @author @wafflemakr @hamaad
 */
contract Distribution is Proxied {

    using SafeMath for uint256;

    struct DistributionStatus {

        uint totalContributionInETH;
        uint totalContributionInKTY;
        uint[5] percentages;
        address winner;
        address topContributor;
        address secondTopContributor;
        mapping(address => bool) otherWinners;
    }

    struct Winner {
        uint EthtoClaim;
        uint KTYtoClaim;
        bool hasRedeemed;
    }

    // Distribution Status by HoneyPotId
    mapping (uint => DistributionStatus) public distributionById;

    // Winner info by Address and HonyPotId
    mapping (address => mapping(uint => Winner)) public winnerByAddress;


    /**
     * @notice prevent interaction if the address is not on record as one of the
     * winning groups or prevent interaction if the address has already claimed
     */
    modifier preventClaims(uint _honeyPotId, address _winner) {
        require(checkAddress(_winner, _honeyPotId), 'Winner does not exists');
        require(hasRedeemed(_winner, _honeyPotId), 'Winner has already claimed');
        _;
    }

    /**
     * @notice creates a new Distribution structure with given honeyPotId
     */
    function newDistribution (
        uint _honeyPotId,
        uint _totalContributionInETH,
        uint _totalContributionInKTY
    )
        public
    {
        uint[5] memory rates = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE)).getDistributionRates();
        distributionById[_honeyPotId].totalContributionInETH = _totalContributionInETH;
        distributionById[_honeyPotId].totalContributionInKTY = _totalContributionInKTY;
        distributionById[_honeyPotId].percentages = rates;
    }

    /**
     * @notice Calculates amount of Eth and KTY token by percentage  of requesting winner
     */
    function calculateAmountByPercentage(address _winner, uint _honeyPotId, uint _perc) internal {
        winnerByAddress[_winner][_honeyPotId].EthtoClaim = distributionById[_honeyPotId].totalContributionInETH * _perc / 100;
        winnerByAddress[_winner][_honeyPotId].KTYtoClaim = distributionById[_honeyPotId].totalContributionInKTY * _perc / 100;
    }

    /**
     * @notice Updates winner address
     */
    function updateWinner(
        address _winner,
        uint _honeyPotId
    )
        external
    {
        distributionById[_honeyPotId].winner = _winner;
        uint _perc = distributionById[_honeyPotId].percentages[0];
        calculateAmountByPercentage(_winner, _honeyPotId, _perc);
    }

    /**
     * @notice Updates highest ETH contributor address
     */
    function updateTopContributor(
        address _top,
        uint _honeyPotId
    )
        external
    {
        distributionById[_honeyPotId].topContributor = _top;
        uint _perc = distributionById[_honeyPotId].percentages[1];
        calculateAmountByPercentage(_top, _honeyPotId, _perc);
    }

    /**
     * @notice Updates second highest ETH contributor address
     */
    function updateSecondTopContributor(
        address _secondTop,
        uint _honeyPotId
    )
        external
    {
        distributionById[_honeyPotId].secondTopContributor = _secondTop;
        uint _perc = distributionById[_honeyPotId].percentages[2];
        calculateAmountByPercentage(_secondTop, _honeyPotId, _perc);
    }

    /**
     * @notice Updates other winners details
     */
    function updateOtherWinners(
        address _otherWinner,
        uint _honeyPotId
    )
        external
    {
        distributionById[_honeyPotId].otherWinners[_otherWinner] = true;
        uint _perc = distributionById[_honeyPotId].percentages[3];
        calculateAmountByPercentage(_otherWinner, _honeyPotId, _perc);
    }

    /**
     * @notice Returns bool wheather address has claimed winning shares in KTY and ETH
     */
    function hasRedeemed(address _winner, uint _honeyPotId) public view returns(bool){
        return winnerByAddress[_winner][_honeyPotId].hasRedeemed;
    }

    /**
     * @notice Eth and token percentage withdrawal scheme
     * Only able to be called when game is over, checks if game is over and them allows claim
     * allow address to claim share and dissallow and subsequent claimes by "modifier".
     * Triggered and calls the "sendEndowmentShare" function ONCE after the game is over.
     */
    function redeem(uint _honeyPotId) public preventClaims(_honeyPotId, msg.sender) {

        uint _sharesETH = winnerByAddress[msg.sender][_honeyPotId].EthtoClaim;
        uint _sharesKTY = winnerByAddress[msg.sender][_honeyPotId].KTYtoClaim;

        //Claim ETH
        msg.sender.transfer(_sharesETH);

        //Claim KTY
        KittieFIGHTToken kittieToken = KittieFIGHTToken(proxy.getContract(CONTRACT_NAME_KITTIEFIGHT_TOKEN));
        kittieToken.transferFrom(proxy.getContract(CONTRACT_NAME_ENDOWMENT), msg.sender, _sharesKTY);

        winnerByAddress[msg.sender][_honeyPotId].hasRedeemed = true;

        sendEndowmentShare();
    }

    /**
     * @notice Triggered and called ONCE, by "redeem" function to allow send of endowment
     * fund share game Honeypot/jackpot funds of Eth and tokens.
     */
    function sendEndowmentShare () internal {
        //TODO
        //KittieFIGHTToken kittieToken = KittieFIGHTToken(getContract(CONTRACT_NAME_KITTIEFIGHT_TOKEN));
        // kittieToken.transferFrom(proxy.getContract(CONTRACT_NAME_ENDOWMENT)
    }

    function checkAddress(
        address _winner,
        uint _honeyPotId
    )
        public view
        returns(bool)
    {
       if (distributionById[_honeyPotId].winner == _winner) return true;
       if (distributionById[_honeyPotId].topContributor == _winner) return true;
       if (distributionById[_honeyPotId].secondTopContributor == _winner) return true;
       if (distributionById[_honeyPotId].otherWinners[_winner]) return true;
       return false;
    }

    function getWinner(
        uint _honeyPotId
    )
        public view
        returns(address)
    {
        return distributionById[_honeyPotId].winner;
    }

}