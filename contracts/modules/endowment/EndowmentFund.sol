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
import "../proxy/Proxied.sol";
import "../../authority/Guard.sol";

import "./Distribution.sol";
import "./Escrow.sol";

/**
 * @title EndowmentFund
 * @dev Responsible for : manage funds
 * @author @vikrammndal @wafflemakr
 */

contract EndowmentFund is Distribution {
    using SafeMath for uint256;

    Escrow public escrow;

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

    /*
    struct KittieTokenTx {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }
    */

    /**
     * @dev for this to work endowment should be tokens!
     */
    function addFundsToEscrow(uint256 _kty_amount, uint256 _eth_amount) external onlyOwner {
        require(address(escrow) != address(0),
            "Error: escrow not initialized");

        require(kittieFightToken.transfer(address(escrow), _kty_amount),
            "Error: Transfer of KTY to Escrow failed");

        require(endowmentDB.updateEndowmentFund(_kty_amount, _eth_amount, false),
            "Error: endowmentDB.updateEndowmentFund(_kty_amount, _eth_amount, false) failed");

        address(escrow).transfer(_eth_amount);
    }

    /**
     * @dev accepts KTY. KTY is stored in escrow
     */
    function contributeKTY(address _sender, uint256 _kty_amount) external returns(bool) {
        require(address(escrow) != address(0), "escrow not initialized");

        // do transfer of KTY
        if (!kittieFightToken.transferFrom(_sender, address(escrow), _kty_amount)){
            return false; // since GM expects bool.
        }

        /*
        // Error: Not registered
        // update DB
        require(endowmentDB.contributeFunds(_sender, 0, 0, _kty_amount),
            'Error: endowmentDB.contributeFunds(_sender, 0, 0, _kty_amount) failed');
        */
        return true;
    }

    /**
     * @dev GM calls as: require( endowmentFund.contributeETH.value( msg.value )( gameId ));
     */
    function contributeETH(uint _gameId) external payable returns(bool) {
        require(address(escrow) != address(0), "escrow not initialized");

        // transfer ETH to Escrow
        if (!address(escrow).send(msg.value)){
            return false; // since GM expects bool
        }

        // check transaction status

        // update DB
        require(endowmentDB.contributeFunds(msg.sender, _gameId, msg.value, 0),
            'Error: endowmentDB.contributeFunds(msg.sender, _gameId, msg.value, 0) failed');

        return true;
    }

    /**
    * @notice MUST BE DONE BEFORE UPGRADING ENDOWMENT AS IT IS THE OWNER
    * @dev change Escrow contract owner before UPGRADING ENDOWMENT AS IT IS THE OWNER
    */
    function transferEscrowOwnership(address payable _newOwner) external onlyOwner {
        escrow.transferOwnership(_newOwner);
    }

    /**
    * @dev transfer Escrow ETH funds
    */
    function transferETHfromEscrow(address payable _someAddress, uint256 _eth_amount) external onlyOwner returns(bool){
        require(address(_someAddress) != address(0), "_someAddress not set");

        // transfer the ETH
        require(escrow.transferETH(_someAddress, _eth_amount),
            "Error: escrow.transferETH(_someAddress, _eth_amount) failed");
        // Update DB. true = deductFunds
        require(endowmentDB.updateEndowmentFund(0, _eth_amount, true),
            "Error: endowmentDB.updateEndowmentFund(0, _eth_amount, true) failed");

        return true;
    }

    /**
    * @dev transfer Escrow KFT funds
    */
    function transferKFTfromEscrow(address payable _someAddress, uint256 _kty_amount) external onlyOwner returns(bool){
        require(address(_someAddress) != address(0), "_someAddress not set");

        // transfer the KTY
        require(escrow.transferKTY(_someAddress, _kty_amount),
            "Error: escrow.transferKTY(_someAddress, _kty_amount) failed");
        // Update DB. true = deductFunds
        require(endowmentDB.updateEndowmentFund(_kty_amount, 0, true),
            "Error: endowmentDB.updateEndowmentFund(_kty_amount, 0, true) failed");

        return true;
    }

    /**
    * @dev Initialize or Upgrade Escrow
    * @notice BEFORE CALLING: Deploy escrow contract and set the owner as EndowmentFund contract
    */
    function initUpgradeEscrow(Escrow _newEscrow) external onlyOwner returns(bool){

        require(address(_newEscrow) != address(0), "_newEscrow address not set");
        _newEscrow.initialize(kittieFightToken);

        // check ownership
        require(_newEscrow.owner() == address(this),
            "Error: The new contract owner is not Endowment. Transfer ownership to Endowment before calling this function");

        if (address(escrow) != address(0)){ // Transfer if any funds

            // transfer all the ETH
            require(escrow.transferETH(address(_newEscrow), address(escrow).balance),
                "Error: Transfer of ETH failed");

            // transfer all the KTY
            uint256 ktyBalance = kittieFightToken.balanceOf(address(escrow));
            require(escrow.transferKTY(address(_newEscrow), ktyBalance),
                "Error: Transfer of KYT failed");

            require(escrow.getBalanceKTY() > 0, "Current escrow is not empty. It has KTY");
            require(escrow.getBalanceETH() > 0, "Current escrow is not empty. It has ETH");

        }
        escrow = _newEscrow;
        return true;
    }

    /**
     * @dev check owner of escrow is still this contract
     */
    function isEndowmentUpgradabe() public view returns(bool){
        return (address(escrow.owner) != address(this));
    }




}
