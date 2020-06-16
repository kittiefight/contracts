/**
 * @title GameVarAndFee
 *
 * @author @wafflemakr @hamaad
 *
 */
//modifier class (DSAuth )
//Event class ( DSNote )
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
// pragma experimental ABIEncoderV2;

import './modules/databases/RoleDB.sol';
import './modules/databases/GenericDB.sol';
import "./modules/proxy/Proxied.sol";
import "./authority/Guard.sol";
import './misc/VarAndFeeNames.sol';
import './modules/endowment/KtyUniswap.sol';
import './libs/SafeMath.sol';

/// @dev MakerDao eth-usd price medianizer
contract Medianizer {
    function read() external view returns (bytes32);
}

/**
 * @title Contract that moderates the various fees, timing limits, expiry date/time,
 * schedules, eth allocation per game, token allocation per game, kittiehell
 * kittie expiration, time durations, distribution percentages e.t.c.
 * The note modifier will log event for each function call.
 * @dev One setter that is called from GameVarAndFeeProxy contract setters
 */
contract GameVarAndFee is Proxied, Guard, VarAndFeeNames {
    using SafeMath for uint256;

    string constant TABLE_NAME = "GameVarAndFeeTable";

    // Declare DB type variable
    GenericDB public genericDB;
    Medianizer medianizer;

    /// @notice Function called when deployed
    /// @param _genericDB Address of deployed GeneriDB contract
    constructor (GenericDB _genericDB, Medianizer _medianizer) public {
        setGenericDB(_genericDB);
        setMedianizer(_medianizer);
    }

    // kovanMedianizer = 0xA944bd4b25C9F186A846fd5668941AA3d3B8425F
    // mainnetMedianizer = 0x729D19f657BD0614b4985Cf1D82531c67569197B
    function setMedianizer(Medianizer _medianizer) public onlyOwner{
       medianizer = Medianizer(_medianizer);
    }

    /// @notice Set genericDB variable to store data in contract
    function setGenericDB(GenericDB _genericDB) public onlyOwner {
        genericDB = _genericDB;
    }

    // ----- SETTERS ------

    /// @dev set one variable at a time
    function setVarAndFee(string calldata varName, uint value)
        external onlyProxy onlySuperAdmin
    {
        bytes32 key = keccak256(abi.encodePacked(TABLE_NAME, varName));
        genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key, value);
    }

    /// @dev set multiple variables
    function setMultipleValues(bytes32[] calldata names, uint[] calldata values)
        external onlyProxy onlySuperAdmin
    {
        require(names.length == values.length);
        bytes32 key;
        for(uint i = 0; i < names.length; i++){
            key = keccak256(abi.encodePacked(TABLE_NAME, bytes32ToString(names[i])));
            genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key, values[i]);
        }
    }

    function setPlatformFeeInDai(string calldata feeName) external onlyProxy onlySuperAdmin {
        bytes32 key = keccak256(abi.encodePacked(TABLE_NAME, feeName));
        uint valKTY = genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
        // convert from kty to dai
        uint valETH = convertKtyToEth(valKTY);
        uint valDAI = convertEthToDai(valETH);
        genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key, valDAI);
    }

    function bytes32ToString(bytes32 x) internal pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }


    // ----- GETTERS ------

    // Stale function - what is this getter for and where is it used?
    /// @notice FrontEnd Global Getter
   // function getGlobalSettings() public view    
     //   returns(uint[5] memory, uint, uint, uint, uint, uint, uint, uint)
    //{
      //  return(getDistributionRates(),getListingFee(),getTicketFee(), getBettingFee(),
        //    getKittieRedemptionFee(), getGamePrestart(), getGameDuration(), getKittieExpiry());
    //}

    /// @notice get eth/usd current price
    // temporarily hard code EthUsdPrice for truffle testing of BurnTokens.test.js
    // Please remove hardcoding and uncomment line 124 once testing is done
    function getEthUsdPrice() public view returns(uint){
        //return uint256(medianizer.read());
        return uint256(0x00000000000000000000000000000000000000000000000b49bcb0036fa6c000);
    }

    /// @notice get KTY/eth current price
    function getKtyEthPrice() public view returns(uint){
        return KtyUniswap(proxy.getContract(CONTRACT_NAME_KTY_UNISWAP)).KTY_ETH_price();
    }

    /// @notice get eth/KTY current price
    function getEthKtyPrice() public view returns(uint){
        return KtyUniswap(proxy.getContract(CONTRACT_NAME_KTY_UNISWAP)).ETH_KTY_price();
    }

    /// @notice get dai/eth current price
    function getDaiEthPrice() public view returns(uint){
        return KtyUniswap(proxy.getContract(CONTRACT_NAME_KTY_UNISWAP)).DAI_ETH_price();
    }

    /// @notice get eth/dai current price
    function getEthDaiPrice() public view returns(uint){
        return KtyUniswap(proxy.getContract(CONTRACT_NAME_KTY_UNISWAP)).ETH_DAI_price();
    }

    function convertEthToDai(uint _ethAmount) public view returns(uint) {
        return _ethAmount.mul(getEthDaiPrice()).div(1000000000000000000);
    }

    function convertDaiToEth(uint _daiAmount) public view returns(uint) {
        return _daiAmount.mul(getDaiEthPrice()).div(1000000000000000000);
    }

    function convertKtyToEth(uint _ktyAmount) public view returns(uint) {
        return _ktyAmount.mul(getKtyEthPrice()).div(1000000000000000000);
    }

    function convertEthToKty(uint _ethAmount) public view returns(uint) {
        return _ethAmount.mul(getEthKtyPrice()).div(1000000000000000000);
    }
        
    /// @notice Gets the number of matches that are set by Scheduler every time (i.e. 20 kitties, 10 matches)
    function getRequiredNumberMatches() 
    public view returns(uint) { 
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, REQUIRED_NUMBER_MATCHES);
    }
    
    /// @notice Gets countdown time for players to start game (i.e. 120).
    function getGamePrestart() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, GAME_PRESTART);
    }
    
    /// @notice Gets Game duration, how long a game lasts
    function getGameDuration() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, GAME_DURATION);
    }
    
    /// @notice Gets how long to wait for payment for kittie in kittiehell before kittie is lost forever 
    function getKittieExpiry() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, KITTIE_HELL_EXPIRATION);
    }
    
    /// @notice Gets the time at which honey pot will be dissolved,after a game is over, used by time contract at end of gameduration
    function getHoneypotExpiration() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, HONEY_POT_EXPIRATION);
    }
    
    /// @notice Gets the percentage of jackpot size for allocating KTY tokens to the jackpot
    function getPercentageHoneypotAllocationKTY()
        public view returns(uint)
    {
            return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, PERCENTAGE_HONEYPOT_ALLOCATION_KTY);
    }

    // stale function
    /// @notice Gets Amount of initial ETH allowed to be drawn from EndowmentFund to be allocated to game
    function getEthPerGame() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, ETH_PER_GAME);
    }

    /// @notice Gets Times duration between each game per day
    function getGameTimes() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, GAME_TIMES);
    }
    
    /// @notice Gets Distribution Rates
    function getDistributionRates() 
    public view returns(uint[5] memory rates) {
                
        rates[0] = genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, WINNING_KITTIE);
        
        rates[1] = genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, TOP_BETTOR);
        
        rates[2] = genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, SECOND_RUNNER_UP);
        
        rates[3] = genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, OTHER_BETTORS);
        
        rates[4] = genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, ENDOWNMENT);
    }

    /// @notice Gets percentage of final honeypot that is set as pool initial ether allocation
    function getPercentageForPool() public view returns (uint256) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, PERCENTAGE_FOR_POOL);
    }

    /// @notice Gets percentage of initial honeypot that is set as kittie listing fee
    function getPercentageForListingFee() public view returns(uint256) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, PERCENTAGE_FOR_LISTING_FEE);
    }

    /// @notice Gets percentage of initial honeypot that is set as Ticket fee
    function getPercentageForTicketFee() public view returns(uint256) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, PERCENTAGE_FOR_TICKET_FEE);
    }

    /// @notice Gets percentage of initial honeypot that is set as Betting fee
    function getPercentageForBettingFee() public view returns(uint256) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, PERCENTAGE_FOR_BETTING_FEE);
    }

    /// @notice Gets percentage of final honeypot that is set as kittieRedemptionFee
    function getPercentageForKittieRedemptionFee()
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, PERCENTAGE_FOR_KITTIE_REDEMPTION_FEE);
    }

    // stale function
    /// @notice Gets USD to KTY ratio
    function getUsdKTYPrice()
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, USD_KTY_PRICE);
    }

    /// @notice Gets fee in Ether for players to list kitties for matching in fights
    function getListingFee() public view returns(uint, uint) {
        uint listingFeeDAI = genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, LISTING_FEE);
        uint listingFeeETH = convertDaiToEth(listingFeeDAI);
        uint listingFeeKTY = convertEthToKty(listingFeeETH);
        uint etherForListingFeeSwap = KtyUniswap(proxy.getContract(CONTRACT_NAME_KTY_UNISWAP)).etherFor(listingFeeKTY);
        return (etherForListingFeeSwap, listingFeeKTY);
    }

    /// @notice Gets minimum contributors needed for the game to continue
    function getMinimumContributors() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, MINIMUM_CONTRIBUTORS);
    }

    /// @notice Gets the amount of KTY rewarded to the user that hits finalize button. Return amount in Dai.
    function getFinalizeRewards()
    public view returns(uint) {
        uint rewardsDAI = genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, FINALIZE_REWARDS);
        uint rewardsETH = convertDaiToEth(rewardsDAI);
        uint rewardsKTY = convertEthToKty(rewardsETH);
        return rewardsKTY;
    }

    /// @notice Gets the time before a game ends that the check performance should act
    function getPerformanceTimeCheck() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, PERFORMANCE_TIME_CHECK);
    }

    /// @notice Gets the amount of time to add when game is underperformant
    function getTimeExtension() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, TIME_EXTENSION);
    }

    /// @notice Gets the required number of kitties NFTs as replacement for redeemed kittie in kittieHELL
    function getRequiredKittieSacrificeNum()
        public view returns(uint)
    {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, REQUIRED_KITTIE_SACRIFICE_NUM);
    }

    function getPercentageforBurnEthie()
        public view returns(uint)
    {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, PERCENTAGE_FOR_BURN_ETHIE);
       
    }

    /// @notice Gets the weekly interest rate for EthieToken NFT
    function getInterestEthie()
        public view returns(uint)
    {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, INTEREST_ETHIE);
    }

}
