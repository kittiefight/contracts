/**
 * @title EndowmentFund
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

/**
 * @title EndowmentFund
 * @dev Responsible for : manage funds
 * @author @vikrammndal @wafflemakr @Xaleee @ziweidream
 */

contract EndowmentFund is Distribution, Guard {
    using SafeMath for uint256;

    Escrow public escrow;

    event WinnerClaimed(uint indexed gameId, address indexed winner, uint256 ethAmount, uint256 ktyAmount, address from);
    event SentKTYtoEscrow(address sender, uint256 ktyAmount, address receiver);
    event SentETHtoEscrow(address sender, uint256 ethAmount, address receiver);

    enum HoneypotState {
        created,
        assigned,
        gameScheduled,
        gameStarted,
        forefeited,
        claiming,
        dissolved
    }

    /**
    * @dev check if enough funds present and maintains balance of tokens in DB
    */
    function generateHoneyPot(uint256 gameId)
    external
    onlyContract(CONTRACT_NAME_GAMECREATION)
    returns (uint, uint) {
        return (endowmentDB.generateHoneyPot(gameId));
    }

    /**
    * @dev winner claims
    */
    function claim(uint256 _gameId) external payable {
        address payable msgSender = address(uint160(getOriginalSender()));

        // Honeypot status
        (uint status, /*uint256 claimTime*/) = endowmentDB.getHoneypotState(_gameId);

        require(uint(HoneypotState.claiming) == status, "1");

        // require(now < claimTime, "2");

        require(!getWithdrawalState(_gameId, msgSender), "3");

        (uint256 winningsETH, uint256 winningsKTY) = getWinnerShare(_gameId, msgSender);

        // make sure enough funds in HoneyPot and update HoneyPot balance
        require(endowmentDB.updateHoneyPotFund(_gameId, winningsKTY, winningsETH, true));

        if (winningsKTY > 0){
            // transfer the KTY
            require(escrow.transferKTY(msgSender, winningsKTY));
        }

        if (winningsETH > 0){
            // transfer the ETH
            require(escrow.transferETH(msgSender, winningsETH));
            // transferETHfromEscrow(msgSender, winningsETH);
        }

        // log tokens sent to an address
        endowmentDB.setTotalDebit(_gameId, msgSender, winningsETH, winningsKTY);

        emit WinnerClaimed(_gameId, msgSender, winningsETH, winningsKTY, address(escrow));
    }

    /**
    * @dev send reward to the user that pressed finalize button
    */
    function sendFinalizeRewards(address user)
        external
        onlyContract(CONTRACT_NAME_GAMEMANAGER)
        returns(bool)
    {
        uint reward = gameVarAndFee.getFinalizeRewards();
        require(transferKTYfromEscrow(address(uint160(user)), reward), "S");
        return true;
    }

    function getWithdrawalState(uint _gameId, address _account) public view returns (bool) {
        (uint256 totalETHdebited, uint256 totalKTYdebited) = endowmentDB.getTotalDebit(_gameId, _account);
        return ((totalETHdebited > 0) && (totalKTYdebited > 0));
    }

    /**
    * @dev updateHoneyPotState
    */
    function updateHoneyPotState(uint256 _gameId, uint _state) public onlyContract(CONTRACT_NAME_GAMEMANAGER) {
        uint256 claimTime;
        if (_state == uint(HoneypotState.claiming)){
            //Send immediately initialEth+15%oflosing and 15%ofKTY to endowment
            (uint256 winningsETH, uint256 winningsKTY) = getEndowmentShare(_gameId);
            endowmentDB.updateEndowmentFund(winningsKTY, winningsETH, false);
            endowmentDB.updateHoneyPotFund(_gameId, winningsKTY, winningsETH, true);
        }
        if(_state == uint(HoneypotState.forefeited)) {
            (uint256 eth, uint256 kty) = endowmentDB.getHoneypotTotal(_gameId);
            endowmentDB.updateEndowmentFund(kty, eth, false);
            endowmentDB.updateHoneyPotFund(_gameId, kty, eth, true);
        }
        endowmentDB.setHoneypotState(_gameId, _state);
    }

    /**
     * @dev Send KTY from EndowmentFund to Escrow
     */
    function sendKTYtoEscrow(uint256 _kty_amount)
        external
        onlySuperAdmin
    {
        require(_kty_amount > 0);

        require(kittieFightToken.transfer(address(escrow), _kty_amount));

        require(endowmentDB.updateEndowmentFund(_kty_amount, 0, false));

        emit SentKTYtoEscrow(address(this), _kty_amount, address(escrow));
    }

    /**
     * @dev Send eth to Escrow
     */
    function sendETHtoEscrow() external payable {
        address msgSender = getOriginalSender();

        require(msg.value > 0);

        address(escrow).transfer(msg.value);

        require(endowmentDB.updateEndowmentFund(0, msg.value, false));

        emit SentETHtoEscrow(msgSender, msg.value, address(escrow));
    }

    /**
     * @dev accepts KTY. KTY is transfered to in escrow
     */
     
    function contributeKTY(address _sender, uint256 _kty_amount) external returns(bool) {
        // do transfer of KTY
        if (!kittieFightToken.transferFrom(_sender, address(escrow), _kty_amount)){
            return false;
        }

        endowmentDB.updateEndowmentFund(_kty_amount, 0, false);

        emit SentKTYtoEscrow(_sender, _kty_amount, address(escrow));

        return true;
    }

    /**
     * @dev GM calls
     */
    function contributeETH(uint _gameId) external payable returns(bool) {
        require(address(escrow) != address(0));
        address msgSender = getOriginalSender();

        require(msg.value > 0);

        // transfer ETH to Escrow
        if (!address(escrow).send(msg.value)){
            return false;
        }

        endowmentDB.updateHoneyPotFund(_gameId, 0, msg.value, false);

        emit SentETHtoEscrow(msgSender, msg.value, address(escrow));

        return true;
    }

    function contributeETH_Ethie()
    external
    onlyContract(CONTRACT_NAME_EARNINGS_TRACKER)
    payable
    returns(bool)
    {
        require(address(escrow) != address(0));
        address msgSender = getOriginalSender();

        require(msg.value > 0);

        // transfer ETH to Escrow
        if (!address(escrow).send(msg.value)){
            return false;
        }

        endowmentDB.updateInvestment(msg.value);

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
    function transferETHfromEscrow(address payable _someAddress, uint256 _eth_amount)
    private
    returns(bool){
        require(address(_someAddress) != address(0));

        // transfer the ETH
        require(escrow.transferETH(_someAddress, _eth_amount));

        // Update DB. true = deductFunds
        require(endowmentDB.updateEndowmentFund(0, _eth_amount, true));

        return true;
    }

    function transferETHfromEscrowWithdrawalPool(address payable _someAddress, uint256 _eth_amount, uint256 _pool_id)
        public
        onlyContract(CONTRACT_NAME_WITHDRAW_POOL)
        returns(bool)
    {
        endowmentDB.subETHfromPool(_eth_amount, _pool_id);
        transferETHfromEscrow(_someAddress, _eth_amount);
        return true;
    }

    function transferETHfromEscrowEarningsTracker(address payable _someAddress, uint256 _eth_amount, bool invested)
        public
        onlyContract(CONTRACT_NAME_EARNINGS_TRACKER)
        returns(bool)
    {
        if(!invested) {
            endowmentDB.subInvestment(_eth_amount);
            require(escrow.transferETH(_someAddress, _eth_amount));
        }
        else
            transferETHfromEscrow(_someAddress, _eth_amount);
        return true;
    }

    /**
    * @dev transfer Escrow KFT funds
    */
    function transferKTYfromEscrow(address payable _someAddress, uint256 _kty_amount)
    private
    returns(bool){
        require(address(_someAddress) != address(0));

        // transfer the KTY
        require(escrow.transferKTY(_someAddress, _kty_amount));

        // Update DB. true = deductFunds
        require(endowmentDB.updateEndowmentFund(_kty_amount, 0, true));

        return true;
    }

    function addETHtoPool(uint256 gameId, address loser)
        external
        onlyContract(CONTRACT_NAME_GAMEMANAGER)
    {
        uint256 totalEthForLoser = gmGetterDB.getTotalBet(gameId, loser);
        uint256 ETHtoPool = totalEthForLoser.mul(gameVarAndFee.getPercentageForPool()).div(1000000);
        endowmentDB.addETHtoPool(gameId, ETHtoPool);
    }

    /**
    * @dev Initialize or Upgrade Escrow
    * @notice BEFORE CALLING: Deploy escrow contract and set the owner as EndowmentFund contract
    */
    function initUpgradeEscrow(Escrow _newEscrow) external onlySuperAdmin returns(bool){

        require(address(_newEscrow) != address(0));
        _newEscrow.initialize(kittieFightToken);

        // check ownership
        require(_newEscrow.owner() == address(this));

        // KTY is set
        require(_newEscrow.getKTYaddress() != address(0));

        if (address(escrow) != address(0)){ // Transfer if any funds

            // transfer all the ETH
            require(escrow.transferETH(address(_newEscrow), address(escrow).balance));

            // transfer all the KTY
            uint256 ktyBalance = kittieFightToken.balanceOf(address(escrow));
            require(escrow.transferKTY(address(_newEscrow), ktyBalance));

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
