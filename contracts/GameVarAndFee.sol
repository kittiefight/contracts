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

import './modules/databases/RoleDB.sol';
import './modules/databases/GenericDB.sol';
import "./modules/proxy/Proxied.sol";
import "./authority/Guard.sol";
import './misc/VarAndFeeNames.sol';

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

    /// @notice for testing only
    function initialize() external onlyOwner {
        RoleDB(proxy.getContract(CONTRACT_NAME_ROLE_DB)).addRole(CONTRACT_NAME_GAMEVARANDFEE, "super_admin", msg.sender);
    }

    // ----- SETTERS ------

    /// @dev we could send two arrays (one with names and other with values)
    ///     to store more than one variable at a time in this function
    function setVarAndFee(string calldata varName, uint value)
        external onlyProxy onlySuperAdmin
    {
        bytes32 key = keccak256(abi.encodePacked(TABLE_NAME, varName));
        genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key, value);
    }

    //TODO: check how to minimize gas, as it runs out of gas
    // function setMultipleValues(uint[] calldata values)
    //     external onlyProxy onlySuperAdmin
    // {
    //     if(values[0] != 0) genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, REQUIRED_NUMBER_MATCHES, values[0]);
    //     if(values[1] != 0) genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, GAME_PRESTART, values[1]);
    //     if(values[2] != 0) genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, GAME_DURATION, values[2]);
    //     if(values[3] != 0) genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, KITTIE_HELL_EXPIRATION, values[3]);
    //     if(values[4] != 0) genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, HONEY_POT_EXPIRATION, values[4]);
    //     if(values[5] != 0) genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, TOKENS_PER_GAME, values[5]);
    //     if(values[6] != 0) genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, ETH_PER_GAME, values[6]);
        // if(values[7] != 0) genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, GAME_TIMES, values[7]);
        // if(values[8] != 0) genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, WINNING_KITTIE, values[8]);
        // if(values[9] != 0) genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, TOP_BETTOR, values[9]);
        // if(values[10] != 0) genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, SECOND_RUNNER_UP, values[10]);
        // if(values[11] != 0) genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, OTHER_BETTORS, values[11]);
        // if(values[12] != 0) genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, ENDOWNMENT, values[12]);
        // if(values[13] != 0) genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, LISTING_FEE, values[13]);
        // if(values[14] != 0) genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, TICKET_FEE, values[14]);
        // if(values[15] != 0) genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, BETTING_FEE, values[15]);
        // if(values[16] != 0) genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, KITTIE_REDEMPTION_FEE, values[16]);
        // if(values[17] != 0) genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, MINIMUM_CONTRIBUTORS, values[17]);
    // }


    // ----- GETTERS ------

    /// @notice get eth/usd current price
    function getEthUsdPrice() public view returns(uint){
        return uint256(medianizer.read());
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
    function getKittieHellExpiration() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, KITTIE_HELL_EXPIRATION);
    }
    
    /// @notice Gets the time at which honey pot will be dissolved,after a game is over, used by time contract at end of gameduration
    function getHoneypotExpiration() 
    public view returns(uint) {
        return genericDB.getUintStorage(TABLE_NAME, HONEY_POT_EXPIRATION);
    }
    
    /// @notice Gets mount of initial KTY Tokens allowed to be drawn from EndowmentFund to be allocated to game
    function getTokensPerGame() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, TOKENS_PER_GAME);
    }
    
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

    /// @notice Gets fee for players to list kitties for matching in fights
    function getListingFee() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, LISTING_FEE);
    }

    /// @notice Gets ticket fee in KTY for betting participators
    function getTicketFee() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, TICKET_FEE);
    }

    /// @notice Gets betting fee in KTY for betting participators
    function getBettingFee() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, BETTING_FEE);
    }

    /// @notice Gets kittieHELL redemption fee in KTY for redeeming kitties
    function getKittieRedemptionFee() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, KITTIE_REDEMPTION_FEE);
    }

    /// @notice Gets minimum contributors needed for the game to continue
    function getMinimumContributors() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, MINIMUM_CONTRIBUTORS);
    }

}
