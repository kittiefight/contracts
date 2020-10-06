/**
* @title TokenDistribution
* @author @Ola, @ziweidream
* @notice This contract allows Investors to claim tokens based on a future token WITHDRAWAL date,
*         and an amount of ether they contributed and bonus percentage of KTY allocations based on
*         amount of Ether contributed.
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

    uint256 public standardRate;

    uint256 public percentBonus;                        // Percentage Bonus
    uint256 public withdrawDate;                        // Withdraw Date
    uint256 public totalNumberOfInvestments;            // total number of investments
    uint256 public totalEtherInvested;                  // total amount of ethers invested from all investments

    // details of an Investment
    struct Investment {
        address investAddr;
        uint256 ethAmount;
        bool hasClaimed;
        uint256 principalClaimed;
        uint256 bonusClaimed;
        uint256 claimTime;
    }

    // mapping investment number to the details of the investment
    mapping(uint256 => Investment) public investments;

    // mapping investment address to the investment ID of all the investments made by this address
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
        uint256 _standardRate,
        uint256 _percentBonus
    )
        external initializer
    {
        Ownable.initialize(_msgSender());

        // set investments
        addInvestments(_investors, _ethAmounts);
        // set ERC20Token contract variable
        setERC20Token(_erc20Token);

        // Set withdraw date
        withdrawDate = _withdrawDate;

        standardRate = _standardRate;

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
        uint256 principal,
        uint256 bonus,
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
        require(investments[investmentID].hasClaimed == false, "Tokens already withdrawn for this investment");
        require(investments[investmentID].ethAmount > 0, "0 ether in this investment");

        // get the ether amount of this investment
        uint256 _ethAmount = investments[investmentID].ethAmount;

        (uint256 _principal, uint256 _bonus, uint256 _principalAndBonus) = calculatePrincipalAndBonus(_ethAmount);

        _updateWithdraw(investmentID, _principal, _bonus);

        // transfer tokens to this investor
        require(token.transfer(msg.sender, _principalAndBonus), "Fail to transfer tokens");

        emit WithDrawn(msg.sender, investmentID, _principal, _bonus, block.timestamp);
        return true;
    }

    /*                                                 SETTER FUNCTIONS                                               */
    /* ============================================================================================================== */
    /**
     * @dev Add new investments
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function addInvestments(address[] memory _investors, uint256[] memory _ethAmounts) public onlyOwner {
        require(_investors.length == _ethAmounts.length, "The number of investing addresses should equal the number of ether amounts");
        for (uint256 i = 0; i < _investors.length; i++) {
             addInvestment(_investors[i], _ethAmounts[i]); 
        }
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

    /**
     * @return uint256 bonus tokens calculated for the amount of ether specified
     */
    function calculatePrincipalAndBonus(uint256 _ether)
        public view returns (uint256, uint256, uint256)
    {
        uint256 principal = _ether.mul(standardRate).div(base18);
        uint256 bonus = _ether.mul(percentBonus).div(base18);
        uint256 principalAndBonus = principal.add(bonus);
        return (principal, bonus, principalAndBonus);
    }

    /**
     * @return address an array of the ID of each investment belonging to the investor
     */
    function getInvestmentIDs(address _investAddr) external view returns (uint256[] memory) {
        return investmentIDs[_investAddr];
    }

    /**
     * @return the details of an investment associated with an investment ID, including the address 
     *         of the investor, the amount of ether invested in this investment, whether bonus tokens
     *         have been claimed for this investment, the amount of bonus tokens already claimed for
     *         this investment(0 if bonus tokens are not claimed yet), the unix time when the bonus tokens
     *         have been claimed(0 if bonus tokens are not claimed yet)
     */
    function getInvestment(uint256 _investmentID) external view
        returns(address _investAddr, uint256 _ethAmount, bool _hasClaimed,
                uint256 _principalClaimed, uint256 _bonusClaimed, uint256 _claimTime)
    {
        _investAddr = investments[_investmentID].investAddr;
        _ethAmount = investments[_investmentID].ethAmount;
        _hasClaimed = investments[_investmentID].hasClaimed;
        _principalClaimed = investments[_investmentID].principalClaimed;
        _bonusClaimed = investments[_investmentID].bonusClaimed;
        _claimTime = investments[_investmentID].claimTime;
    }
    

    /*                                                 PRIVATE FUNCTIONS                                             */
    /* ============================================================================================================== */
    /**
     * @param _investmentID uint256 investment ID of the investment for which tokens are withdrawn
     * @param _bonus uint256 tokens distributed to this investor
     * @dev this function updates the storage upon successful withdraw of tokens.
     */
    function _updateWithdraw(uint256 _investmentID, uint256 _principal, uint256 _bonus) 
        private
    {
        investments[_investmentID].hasClaimed = true;
        investments[_investmentID].principalClaimed = _principal;
        investments[_investmentID].bonusClaimed = _bonus;
        investments[_investmentID].claimTime = block.timestamp;
        investments[_investmentID].ethAmount = 0;
    }

    /**
     * @dev Add one new investment
     */
    function addInvestment(address _investor, uint256 _eth) private {
        uint256 investmentID = totalNumberOfInvestments.add(1);
        investments[investmentID].investAddr = _investor;
        investments[investmentID].ethAmount = _eth;
   
        totalEtherInvested = totalEtherInvested.add(_eth);
        totalNumberOfInvestments = investmentID;

        investmentIDs[_investor].push(investmentID);
    }
}
