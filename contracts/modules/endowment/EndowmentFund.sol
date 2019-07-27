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
import '../../authority/Guard.sol';

/**
 * @title EndowmentFund
 * @dev Responsible for : manage funds
 * @author @vikrammndal @wafflemakr
 */

contract EndowmentFund is Distribution, Guard {
    using SafeMath for uint256;

    Escrow public escrow;

    event WinnerClaimed(address winner, uint256 ethAmount, uint256 ktyAmount, address from);
    event SentKTYtoEscrow(address sender, uint256 ktyAmount, address receiver);
    event SentETHtoEscrow(address sender, uint256 ethAmount, address receiver);

    /// @notice  the count of all invocations of `generatePotId`.
    uint256 public potRequestCount;

    enum HoneypotState {
        created,
        assigned,
        gameScheduled,
        gameStarted,
        forefeited,
        claiming
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

    function generateHoneyPot(uint gameId) external onlyContract(CONTRACT_NAME_GAMEMANAGER) returns (uint, uint) {
        uint ktyAllocated = gameVarAndFee.getTokensPerGame();
        require(endowmentDB.allocateKTY(ktyAllocated), 'Error: endowmentDB.allocateKTY(ktyAllocated) failed');
        uint ethAllocated = gameVarAndFee.getEthPerGame();
        require(endowmentDB.allocateETH(ethAllocated), 'Error: endowmentDB.allocateETH(ethAllocated) failed');

        uint potId = generatePotId();

        Honeypot memory honeypot;
        // honeypot.gameId = potId;
        honeypot.gameId = gameId;
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
    function updateHoneyPotState(uint256 _gameId, uint _state) public onlyContract(CONTRACT_NAME_GAMEMANAGER) {
        uint256 claimTime;
        if (_state == uint(HoneypotState.claiming)){
            claimTime = now.add(gameVarAndFee.getHoneypotExpiration());
        }
        endowmentDB.setHoneypotState(_gameId, _state, claimTime);
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

    /**
    * @dev winner claims
    */
    function claim(uint256 _gameId) external payable {
        //address payable msgSender = getOriginalSender();
        address payable msgSender = address(uint160(getOriginalSender()));
        // status
        (uint status, uint256 claimTime) = endowmentDB.getHoneypotState(_gameId);
        require(uint(HoneypotState.claiming) == status, "HoneypotState can not be claimed");

        // get the time when state changed to claming start and add to it the Expiration time
        require(now < claimTime, "Time to claim is over");
    
        (uint256 winningsETH, uint256 winningsKTY) = getWinnerShare(_gameId, msgSender);
        if (winningsKTY > 0){
            transferKFTfromEscrow(msgSender, winningsKTY);
        }

        if (winningsETH > 0){
            transferETHfromEscrow(msgSender, winningsETH);
        }

        // log debit of funds
        endowmentDB.debitFunds(_gameId, msgSender, winningsETH, winningsKTY);

        emit WinnerClaimed(msgSender, winningsETH, winningsKTY, address(escrow));
    }

    function getWithdrawalState(uint _gameId, address _account) public view returns (bool) {
        address msgSender = getOriginalSender();
        (uint256 totalETHdebited, uint256 totalKTYdebited) = endowmentDB.getTotalDebit(_gameId, _account);
        return ((totalETHdebited > 0) && (totalKTYdebited > 0)); // since payout is in full not in parts
    }


    /**
     * @dev Send KTY from EndowmentFund to Escrow
     */
    function sendKTYtoEscrow(uint256 _kty_amount) external onlySuperAdmin {

        require(address(escrow) != address(0),
            "Error: escrow not initialized");

        require(_kty_amount > 0,
            "Error: _kty_amount is zero");

        require(kittieFightToken.transfer(address(escrow), _kty_amount),
            "Error: Transfer of KTY to Escrow failed");

        require(endowmentDB.updateEndowmentFund(_kty_amount, 0, false),
            "Error: endowmentDB.updateEndowmentFund(_kty_amount, 0, false) failed");

        emit SentKTYtoEscrow(address(this), _kty_amount, address(escrow));
    }

    /**
     * @dev Send eth to Escrow
     */
    function sendETHtoEscrow() external payable {
        address msgSender = getOriginalSender();

        require(address(escrow) != address(0),
            "Error: escrow not initialized");

        require(msg.value > 0,
            "Error: msg.value is zero");

        address(escrow).transfer(msg.value);

        require(endowmentDB.updateEndowmentFund(0, msg.value, false),
            "Error: endowmentDB.updateEndowmentFund(0, msg.value, false) failed");

        emit SentETHtoEscrow(msgSender, msg.value, address(escrow));
    }

    /**
     * @dev accepts KTY. KTY is stored in escrow
     */
    function contributeKTY(address _sender, uint256 _kty_amount) external returns(bool) {
        require(address(escrow) != address(0), "escrow not initialized");

        // do transfer of KTY
        if (!kittieFightToken.transferFrom(_sender, address(escrow), _kty_amount)){
            return false;
        }
        // update DB
        require(endowmentDB.contributeFunds(_sender, 0, 0, _kty_amount),
            'Error: endowmentDB.contributeFunds(_sender, 0, 0, _kty_amount) failed');

        emit SentKTYtoEscrow(_sender, _kty_amount, address(escrow));

        return true;
    }

    /**
     * @dev GM calls
     */
    function contributeETH(uint _gameId) external payable returns(bool) {
        require(address(escrow) != address(0), "escrow not initialized");
        address msgSender = getOriginalSender();

        // transfer ETH to Escrow
        if (!address(escrow).send(msg.value)){
            return false;
        }

        // update DB
        require(endowmentDB.contributeFunds(msgSender, _gameId, msg.value, 0),
            'Error: endowmentDB.contributeFunds(msgSender, _gameId, msg.value, 0) failed');

        emit SentETHtoEscrow(msgSender, msg.value, address(escrow));

        return true;
    }

    /**
    * @notice MUST BE DONE BEFORE UPGRADING ENDOWMENT AS IT IS THE OWNER
    * @dev change Escrow contract owner before UPGRADING ENDOWMENT AS IT IS THE OWNER
    */
    function transferEscrowOwnership(address payable _newOwner) external onlySuperAdmin {
        escrow.transferOwnership(_newOwner);
    }

    /**
    * @dev transfer Escrow ETH funds
    */
    function transferETHfromEscrow(address payable _someAddress, uint256 _eth_amount) public onlySuperAdmin returns(bool){
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
    function transferKFTfromEscrow(address payable _someAddress, uint256 _kty_amount) public onlySuperAdmin returns(bool){
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
    function initUpgradeEscrow(Escrow _newEscrow) external onlySuperAdmin returns(bool){

        require(address(_newEscrow) != address(0), "_newEscrow address not set");
        _newEscrow.initialize(kittieFightToken);

        // check ownership
        require(_newEscrow.owner() == address(this),
            "Error: The new contract owner is not Endowment. Transfer ownership to Endowment before calling this function");

        // KTY is set
        require(_newEscrow.getKTYaddress() != address(0), "kittieFightToken not initialized in Escrow");

        if (address(escrow) != address(0)){ // Transfer if any funds

            // transfer all the ETH
            require(escrow.transferETH(address(_newEscrow), address(escrow).balance),
                "Error: Transfer of ETH failed");

            // transfer all the KTY
            uint256 ktyBalance = kittieFightToken.balanceOf(address(escrow));
            require(escrow.transferKTY(address(_newEscrow), ktyBalance),
                "Error: Transfer of KYT failed");

        }

        escrow = _newEscrow;
        return true;
    }


    /**
     * @dev Do not upgrade Endowment if owner of escrow is still this contract's address
     * Steps:
     * deploy new Endowment
     * set owner of escrow to new Endowment adrress using endowment.transferEscrowOwnership(new Endowment adrress)
     * than set the new Endowment adrress in proxy
     */
    function isEndowmentUpgradabe() public view returns(bool){
        return (address(escrow.owner) != address(this));
    }




}

/**
Change log

2019-07-26 11:17:05
Aadded Guard to EndowmentFund
Use getOriginalSender()insteads of msg.sender
Replaced onlyOwner with onlySuperAdmin

2019-07-26 11:51:59
Improve getWithdrawalState() - just set staus when fund is withdrawn

2019-07-26 12:01:49
git push

2019-07-27 10:09:34
small change

*/