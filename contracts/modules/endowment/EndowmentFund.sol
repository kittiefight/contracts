/**
 * @title EndowmentFund
 *
 *
 */
//
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

import "./Distribution.sol";
import "../proxy/Proxied.sol";
import "../databases/EndowmentDB.sol";
import "../../GameVarAndFee.sol";
import "../../interfaces/ERC20Standard.sol";
import "./Escrow.sol";

/**
 * @title EndowmentFund
 * @dev Responsible for : manage funds
 * @author @vikrammndal @wafflemakr
 */

contract EndowmentFund is Proxied, Distribution {
    using SafeMath for uint256;

    GameVarAndFee public gameVarAndFee;
    EndowmentDB public endowmentDB;
    ERC20Standard public kittieFightToken;
    Escrow public escrow;

    /// @notice  the count of all invocations of `generatePotId`.
    uint256 public potRequestCount;

    /**
    * @dev Sets related contracts
    * @dev Can be called only by the owner of this contract
    */
    function initialize() external onlyOwner {

        endowmentDB = EndowmentDB(proxy.getContract(CONTRACT_NAME_ENDOWMENT_DB));
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        //kittieFightToken = ERC20Standard(proxy.getContract('MockERC20Token'));
        kittieFightToken = ERC20Standard(proxy.getContract(CONTRACT_NAME_KITTIEFIGHTTOKEN));
        escrow = Escrow(proxy.getContract(CONTRACT_NAME_ESCROW));
    }

    enum HoneypotState {
        created,
        assigned,
        gameScheduled,
        gameStarted,
        forefeited,
        claimed
    }

    struct Honeypot {
        uint gameId;
        HoneypotState state;
        string forfeitReason;
        uint dissolveTime;
        uint gameEndTime;
        uint createdTime;
        uint ktyTotal;
        uint ethTotal;
    }

    function generateHoneyPot() external onlyContract(CONTRACT_NAME_GAMEMANAGER) returns (uint, uint) {
        uint ktyAllocated = gameVarAndFee.getTokensPerGame();
        require(endowmentDB.allocateKTY(ktyAllocated), 'Error: endowmentDB.allocateKTY(ktyAllocated) failed');
        uint ethAllocated = gameVarAndFee.getEthPerGame();
        require(endowmentDB.allocateETH(ethAllocated), 'Error: endowmentDB.allocateETH(ethAllocated) failed');

        uint potId = generatePotId();

        Honeypot memory honeypot;
        honeypot.gameId = potId;
        honeypot.state = HoneypotState.created;
        honeypot.createdTime = now;
        honeypot.ktyTotal = ktyAllocated;
        honeypot.ethTotal = ethAllocated;

        endowmentDB.createHoneypot(
            honeypot.gameId,
            uint(honeypot.state),
            honeypot.createdTime,
            honeypot.ktyTotal,
            honeypot.ethTotal
        );

    return (potId, ethAllocated);
    }

    /**
    * @dev updateHoneyPotState
    */
    function updateHoneyPotState(uint256 _potId, uint _state) public onlyContract(CONTRACT_NAME_GAMEMANAGER) {
        endowmentDB.setHoneypotState(_potId, _state);
    }


    struct KittieTokenTx {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }

    /**
     * @dev will be called by bet from GM
     *
     */
    function contributeKTY(address _sender, uint256 _kty_amount) external returns(bool) {

        // do transfer of KTY
        require(kittieFightToken.transferFrom(_sender, address(escrow), _kty_amount), "kittieFightToken.transferFrom() failed");

        // update DB
        require(endowmentDB.contributeFunds(_sender, 0, 0, _kty_amount),
            'Error: endowmentDB.contributeFunds(_sender, 0, 0, _kty_amount) failed');

        return true;
    }

    /**
     * @dev called by GameMangar
     *
     */
    function contributeETH(uint _gameId) external returns(bool) {

        // transfer ETH to Escrow

        // update DB
        uint _eth_amount = 0; // msg.value is availabe only in payable function
        require(endowmentDB.contributeFunds(msg.sender, _gameId, _eth_amount, 0),
            'Error: endowmentDB.contributeFunds(msg.sender, _gameId, _eth_amount, 0) failed');

        return true;
    }

    /** @notice  Returns a fresh unique identifier.
    *
    * @dev the generation scheme uses three components.
    * First, the blockhash of the previous block.
    * Second, the deployed address.
    * Third, the next value of the counter.
    * This ensure that identifiers are unique across all contracts
    * following this scheme, and that future identifiers are
    * unpredictable.
    *
    * @return a 32-byte unique identifier.
    */
    function generatePotId() internal returns (uint potId) {
    return uint(keccak256(
        abi.encodePacked(blockhash(block.number - 1), address(this), ++potRequestCount)
        ));
    }

}