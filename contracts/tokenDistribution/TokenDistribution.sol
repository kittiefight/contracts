/**
* @title YieldFarming
* @author @Ola, @ziweidream
* @notice This contract will track uniswap pool contract and addresses that deposit "UNISWAP pool" tokens 
*         and allow each individual address to DEPOSIT and  withdraw percentage of KTY and SDAO tokens 
*         according to number of "pool" tokens they own, relative to total pool tokens.
*         This contract contains two tokens in contract KTY and SDAO. The contract will also return 
*         certain statistics about rates, availability and timing period of the program.
*/
pragma solidity ^0.5.5;

import "../libs/openzeppelin_upgradable_v2_5_0/ownership/Ownable.sol";
import "../libs/SafeMath.sol";
import "../interfaces/ERC20Standard.sol";

contract TokenDistribution is Ownable {
    using SafeMath for uint256;

    /*                                               GENERAL VARIABLES                                                */
    /* ============================================================================================================== */

    ERC20Standard public token;                         // ERC20Token contract variable

    uint256 constant internal base18 = 1000000000000000000;

    uint256 public percentBonus;
    uint256 public withdrawDate;

    uint256 public totalNumberOfInvestments;

    uint256 public totalEtherInvested;

    struct Investment {
        address investAddr;
        uint256 ethAmount;
        bool hasClaimedBonus;
        uint256 bonusClaimed;
        uint256 bonusClaimTime;
    }

    // mapping investment number to the details of the investment
    mapping(uint256 => Investment) public investments;

    // mapping investment address to its investment ID
    mapping(address => uint256[]) public investmentIDs;

    uint256 private unlocked;

    /*                                                   MODIFIERS                                                    */
    /* ============================================================================================================== */
    modifier lock() {
        require(unlocked == 1, 'Locked');
        unlocked = 0;
        _;
        unlocked = 1;
    }          

    /*                                                   INITIALIZER                                                  */
    /* ============================================================================================================== */
    function initialize
    (
        address[] calldata _investors,
        uint256[] calldata _ethAmounts,
        ERC20Standard _erc20Token,
        uint256 _withdrawDate,
        uint256 _percentBonus
    )
        external initializer
    {
        Ownable.initialize(_msgSender());

        // set investors address
        for (uint256 i = 0; i < _investors.length; i++) {
            addInvestments(_investors[i], _ethAmounts[i]);
        }
        // set ERC20Token contract variable
        setERC20Token(_erc20Token);

        // Set withdraw date
        withdrawDate = _withdrawDate;

        // Set percentage bonus
        percentBonus = _percentBonus;

        //Reentrancy lock
        unlocked = 1;
    }

    /*                                                      EVENTS                                                    */
    /* ============================================================================================================== */
    event WithDrawn(
        address indexed investor,
        uint256 indexed investmentID,
        uint256 indexed bonus, 
        uint256 withdrawTime
    );

    /*                                                 YIELD FARMING FUNCTIONS                                        */
    /* ============================================================================================================== */

    /**
     * @notice Withdraw tokens
     * @param investmentID uint256 investment ID of the investment for which the bonus tokens are distributed
     * @return bool true if the withdraw is successful
     */
    function withdraw(uint256 investmentID) external lock returns (bool) {
        require(investments[investmentID].investAddr == msg.sender, "You are not the investor of this investment");
        require(block.timestamp >= withdrawDate, "Can only withdraw after withdraw date");
        require(investments[investmentID].hasClaimedBonus == false, "Tokens already withdrawn for this investment");
        require(investments[investmentID].ethAmount > 0, "0 ether in this investment");

        // get the ether amount of this investment
        uint256 _ethAmount = investments[investmentID].ethAmount;

        uint256 _bonus = calculateBonus(_ethAmount);

        _updateWithdraw(investmentID, _bonus);

        // transfer tokens to this investor
        require(token.transfer(msg.sender, _bonus), "Fail to transfer tokens");

        emit WithDrawn(msg.sender, investmentID, _bonus, block.timestamp);
        return true;
    }

    /*                                                 SETTER FUNCTIONS                                               */
    /* ============================================================================================================== */
    /**
     * @dev Add new investor
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function addInvestments(address _investor, uint256 _eth) public onlyOwner {
        uint256 investmentID = totalNumberOfInvestments.add(1);
        investments[investmentID].investAddr = _investor;
        investments[investmentID].ethAmount = _eth;
   
        totalEtherInvested = totalEtherInvested.add(_eth);
        totalNumberOfInvestments = investmentID;

        investmentIDs[_investor].push(investmentID);
    }

    /**
     * @dev Set ERC20Token contract
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setERC20Token(ERC20Standard _erc20Token) public onlyOwner {
        token = _erc20Token; 
    }

    /**
     * @dev Set percentage bonus. Percentage bonus is amplified 10**8 times for float precision
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setPercentBonus(uint256 _percentBonus) public onlyOwner {
        percentBonus = _percentBonus; 
    }

    /**
     * @notice This function transfers tokens out of this contract to a new address
     * @dev This function is used to transfer unclaimed KittieFightToken to a new address,
     *      or transfer other tokens erroneously tranferred to this contract back to their original owner
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function returnTokens(address _token, uint256 _amount, address _newAddress) external onlyOwner {
        require(block.timestamp >= withdrawDate.add(7 * 24 * 7), "Cannot return any token within 7 days of withdraw date");
        uint256 balance = ERC20Standard(_token).balanceOf(address(this));
        require(_amount <= balance, "Exceeds balance");
        require(ERC20Standard(_token).transfer(_newAddress, _amount), "Fail to transfer tokens");
    }

    /**
     * @notice Set withdraw date for the token
     * @param _withdrawDate uint256 withdraw date for the token
     * @dev    This function can only be carreid out by the owner of this contract.
     */
    function setWithdrawDate(uint256 _withdrawDate) public onlyOwner {
        withdrawDate = _withdrawDate;
    }

    /*                                                 GETTER FUNCTIONS                                               */
    /* ============================================================================================================== */
    
    /**
     * @return true and 0 if it is time to withdraw, false and time until withdraw if it is not the time to withdraw yet
     */
    function canWithdraw() public view returns (bool, uint256) {
        if (block.timestamp >= withdrawDate) {
            return (true, 0);
        } else {
            return (false, withdrawDate.sub(block.timestamp));
        }
    }

    function calculateBonus(uint256 _ether) public view returns (uint256) {
        return _ether.mul(percentBonus).div(base18);
    }

    function getInvestmentIDs(address _investAddr) external view returns (uint256[] memory) {
        return investmentIDs[_investAddr];
    }


    function getInvestment(uint256 _investmentID) external view
        returns(address _investAddr, uint256 _ethAmount, bool _hasClaimedBonus,
                uint256 _bonusClaimed, uint256 _bonusClaimTime)
    {
        _investAddr = investments[_investmentID].investAddr;
        _ethAmount = investments[_investmentID].ethAmount;
        _hasClaimedBonus = investments[_investmentID].hasClaimedBonus;
        _bonusClaimed = investments[_investmentID].bonusClaimed;
        _bonusClaimTime = investments[_investmentID].bonusClaimTime;
    }
    

    /*                                                 PRIVATE FUNCTIONS                                             */
    /* ============================================================================================================== */
    /**
     * @param _investmentID uint256 investment ID of the investment for which tokens are withdrawn
     * @param _bonus uint256 tokens distributed to this investor
     */
    function _updateWithdraw(uint256 _investmentID, uint256 _bonus) 
        private
    {
        investments[_investmentID].hasClaimedBonus == true;
        investments[_investmentID].bonusClaimed = _bonus;
        investments[_investmentID].bonusClaimTime = block.timestamp;
        investments[_investmentID].ethAmount = 0;
    }
}
