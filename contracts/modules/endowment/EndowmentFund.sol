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

//import "../proxy/Proxied.sol";
import "../../authority/Guard.sol";
import "../databases/EndowmentDB.sol";
import "../../GameVarAndFee.sol";
import "../../interfaces/ERC20Standard.sol";

/**
 * @title EndowmentFund
 * @dev Responsible for : manage funds
 * @author @vikrammndal @wafflemakr)
 */

//contract EndowmentFund is Proxied {
contract EndowmentFund is Guard {
    using SafeMath for uint256;

    GameVarAndFee public gameVarAndFee;
    EndowmentDB public endowmentDB;

    /// @notice  the count of all invocations of `generatePotId`.
    uint256 public potRequestCount;

    constructor() public {
        potRequestCount = 0;
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        endowmentDB = EndowmentDB(proxy.getContract(CONTRACT_NAME_ENDOWMENT_DB));
    }

    /**
    * @notice Owner can call this function to update the needed contract for checking conditions.
    * @dev contract addresses are stored in proxy
    */
    function updateContracts() external onlyOwner {
        gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
        endowmentDB = EndowmentDB(proxy.getContract(CONTRACT_NAME_ENDOWMENT_DB));
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

    /**
    * @dev updateHoneyPotState called from?
    */
    function updateHoneyPotState(uint256 potId, uint state) private {
        //
    }

    function generateHoneyPot() external onlyContract(CONTRACT_NAME_GAMEMANAGER) returns (uint, uint) {
        uint ktyAllocated = gameVarAndFee.getTokensPerGame();
        require(endowmentDB.allocateKTY(ktyAllocated));
        uint ethAllocated = gameVarAndFee.getEthPerGame();
        require(endowmentDB.allocateETH(ethAllocated));

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


    struct KittieTokenTx {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }

    /**
     * @dev msg.sender = Guard Contract -> getOriginalSender()
     *
     */
    function contributeKFT(address _sender, uint _value) private onlyBettor() {
        require(endowmentDB.contibuteFunds(_sender, 0, 0, _value));
    }

    /**
     * @dev msg.sender = Guard Contract -> getOriginalSender()
     *
     */
    function contributeETH(uint _gameId) external payable {
        // (address account, uint gameId, uint ethContribution, uint ktyContribution)
        require(endowmentDB.contibuteFunds(msg.sender, _gameId, msg.value, 0));
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

/*
    function tokenFallback(address _from, uint _value, bytes calldata _data) external {
        /* tokenTx variable is analogue of msg variable of Ether transaction:
        *  tokenTx.sender is person who initiated this token transaction   (analogue of msg.sender)
        *  tokenTx.value the number of tokens that were sent   (analogue of msg.value)
        *  tokenTx.data is data of token transaction   (analogue of msg.data)
        *  tokenTx.sig is 4 bytes signature of function if data of token transaction is a function execution
        * /
        KittieTokenTx memory tokenTx;
        tokenTx.sender = _from;
        tokenTx.value = _value;
        tokenTx.data = _data;
        (bytes4 _sig, uint _gameId) = abi.decode(_data, (bytes4, uint256));
        tokenTx.sig = _sig;

        require(msg.sender == address(proxy.getContract(CONTRACT_NAME_KITTIEFIGHTOKEN)));

        // invoke the target function
        (bool _ok, ) = address(this).call(abi.encodeWithSelector(tokenTx.sig, _gameId, tokenTx.sender, tokenTx.value));
        require(_ok);
    }
    */


}    