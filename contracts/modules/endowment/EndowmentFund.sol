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
import "./Escrow.sol";

/**
 * @title EndowmentFund
 * @dev Responsible for : manage funds
 * @author @vikrammndal @wafflemakr
 */

contract EndowmentFund is Distribution {
    using SafeMath for uint256;

    Escrow escrow;

    /// @notice  the count of all invocations of `generatePotId`.
    uint256 public potRequestCount;

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
        endowmentDB.setHoneypotState(_potId,_state);
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
        if (!kittieFightToken.transferFrom(_sender, address(escrow), _kty_amount)){
            return false; // since GM expects bool.
        }

        // update DB
        require(endowmentDB.contributeFunds(_sender, 0, 0, _kty_amount),
            'Error: endowmentDB.contributeFunds(_sender, 0, 0, _kty_amount) failed');

        return true;
    }

    /**
     * @dev GM calls as: require( endowmentFund.contributeETH.value( msg.value )( gameId ));
     */
    function contributeETH(uint _gameId) external payable returns(bool) {

        // transfer ETH to Escrow
        //address(escrow).transfer(msg.value); // with through if not successful
        if (!address(escrow).send(msg.value)){
            return false; // since GM expects bool
        }

        // to do - check transaction status

        // update DB
        require(endowmentDB.contributeFunds(msg.sender, _gameId, msg.value, 0),
            'Error: endowmentDB.contributeFunds(msg.sender, _gameId, msg.value, 0) failed');

        return true;
    }

    /**
     * Escrow is created and owned by Endowment
     * OR Do we deply escrow and than transfer ownership to Endowment?
     */
    function initEscrow() external onlyOwner {

        escrow = new Escrow();

    }

    /**
    * @notice MUST BE DONE BEFORE UPGRADING ENDOWMENT AS IT IS THE OWNER
    * @dev change Escrow contract owner before UPGRADING ENDOWMENT AS IT IS THE OWNER
    */
    function transferEscrowOwnership(address payable _newOwner) external onlyOwner {
        escrow.transferOwnership(_newOwner);
    }

    /**
    * @dev transfer old Escrow funds to new Escrow
    */
    function transferEscrow(address payable newEscrow) external onlyOwner {

        // transfer the ETH
        escrow.transferETH(newEscrow, address(escrow).balance);

        // transfer the KTY
        uint256 ktyBalance = kittieFightToken.balanceOf(address(escrow));
        escrow.transferKTY(newEscrow, ktyBalance);
    }



}