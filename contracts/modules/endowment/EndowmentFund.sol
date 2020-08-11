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
    event EthSwappedforKTY(address sender, uint256 ethAmount, uint256 ktyAmount, address ktyReceiver);

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
    * @dev winner claims
    */
    function claim(uint256 _gameId) external onlyProxy {
        address payable msgSender = address(uint160(getOriginalSender()));

        // Honeypot status
        (uint status, /*uint256 claimTime*/) = endowmentDB.getHoneypotState(_gameId);

        require(uint(HoneypotState.claiming) == status);

        // require(now < claimTime, "2");

        bool hasClaimed = AccountingDB(proxy.getContract(CONTRACT_NAME_ACCOUNTING_DB)).getWithdrawalState(_gameId, msgSender);

        require(hasClaimed == false);

        (uint256 winningsETH, uint256 winningsKTY) = getWinnerShare(_gameId, msgSender);

        // make sure enough funds in HoneyPot and update HoneyPot balance
        endowmentDB.updateHoneyPotFund(_gameId, winningsKTY, winningsETH, true);

        if (winningsKTY > 0){
            // transfer the KTY
            escrow.transferKTY(msgSender, winningsKTY);
            // transfer the ETH
            escrow.transferETH(msgSender, winningsETH);
        }

        // log tokens sent to an address
        AccountingDB(proxy.getContract(CONTRACT_NAME_ACCOUNTING_DB)).setTotalDebit(_gameId, msgSender, winningsETH, winningsKTY);

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
        uint256 reward = gameVarAndFee.getFinalizeRewards();
        transferKTYfromEscrow(address(uint160(user)), reward);
        return true;
    }

    /**
     * @dev Send KTY from EndowmentFund to Escrow
     */
    function sendKTYtoEscrow(uint256 _kty_amount)
        external
        onlySuperAdmin
    {
        require(_kty_amount > 0);

        kittieFightToken.transfer(address(escrow), _kty_amount);

        endowmentDB.updateEndowmentFund(_kty_amount, 0, false);

        emit SentKTYtoEscrow(address(this), _kty_amount, address(escrow));
    }

    /**
     * @dev Send eth to Escrow
     */
    function sendETHtoEscrow() external onlyContract(CONTRACT_NAME_GAMEMANAGER) payable {
        address msgSender = getOriginalSender();

        require(msg.value > 0);

        address(escrow).transfer(msg.value);

        endowmentDB.updateEndowmentFund(0, msg.value, false);

        emit SentETHtoEscrow(msgSender, msg.value, address(escrow));
    }

    /**
     * @dev accepts KTY. KTY is swapped in uniswap.
     * @dev KTY is sent to escrow. Ether is sent to KTY-WETH pair contract by the user.
     * @dev Escrow sends 2x of KTY received in swap to KTY-WETH pair contract to maintain the
     *      original ether to KTY ratio.
     */
    function contributeKTY(address _sender, uint256 _ether_amount_swap, uint256 _kty_amount) external 
            only3Contracts(CONTRACT_NAME_GAMECREATION, CONTRACT_NAME_GAMEMANAGER, CONTRACT_NAME_EARNINGS_TRACKER) 
            payable returns(bool) {
        HoneypotAllocationAlgo(proxy.getContract(CONTRACT_NAME_HONEYPOT_ALLOCATION_ALGO)).swapEtherForKTY.value(msg.value)(_ether_amount_swap, address(escrow));

        endowmentDB.updateEndowmentFund(_kty_amount, 0, false);

        emit EthSwappedforKTY(_sender, msg.value, _kty_amount, address(escrow));

        return true;
    }

    /**
     * @dev GM calls
     */
    function contributeETH(uint _gameId) external onlyContract(CONTRACT_NAME_GAMEMANAGER) payable returns(bool) {
        // require(address(escrow) != address(0));
        address msgSender = getOriginalSender();

        require(msg.value > 0);

        // transfer ETH to Escrow
        address(escrow).transfer(msg.value);

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
        // require(address(escrow) != address(0));
        address msgSender = getOriginalSender();

        require(msg.value > 0);

        // transfer ETH to Escrow
        address(escrow).transfer(msg.value);

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
        // require(address(_someAddress) != address(0));

        // transfer the ETH
        escrow.transferETH(_someAddress, _eth_amount);

        // Update DB. true = deductFunds
        endowmentDB.updateEndowmentFund(0, _eth_amount, true);

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
            escrow.transferETH(_someAddress, _eth_amount);
        }
        else
            transferETHfromEscrow(_someAddress, _eth_amount);
        return true;
    }

    /**
    * @dev transfer Escrow KFT funds
    */
    function transferKTYfromEscrow(address _someAddress, uint256 _kty_amount)
    private
    returns(bool){
        // require(address(_someAddress) != address(0));

        // transfer the KTY
        escrow.transferKTY(_someAddress, _kty_amount);

        // Update DB. true = deductFunds
        endowmentDB.updateEndowmentFund(_kty_amount, 0, true);

        return true;
    }

    /**
    * @dev Initialize or Upgrade Escrow
    * @notice BEFORE CALLING: Deploy escrow contract and set the owner as EndowmentFund contract
    */
    function initUpgradeEscrow(Escrow _newEscrow, uint256 _transferNum)
        external
        onlySuperAdmin
        multiSigFundsMovement(_transferNum, address(_newEscrow))
    {
        // require(address(_newEscrow) != address(0));
        _newEscrow.initialize(kittieFightToken);

        // check ownership
        // require(_newEscrow.owner() == address(this));

        // KTY is set
        // require(_newEscrow.getKTYaddress() != address(0));

        if (address(escrow) != address(0)){ // Transfer if any funds

            // transfer all the ETH
            escrow.transferETH(address(_newEscrow), address(escrow).balance);

            // transfer all the KTY
            uint256 ktyBalance = kittieFightToken.balanceOf(address(escrow));
            escrow.transferKTY(address(_newEscrow), ktyBalance);
        }

        escrow = _newEscrow;
    }
}
