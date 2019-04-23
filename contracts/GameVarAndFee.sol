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
import "./DSNote.sol";
import './misc/VarAndFeeNames.sol';


/**
 * @title Contract that moderates the various fees, timing limits, expiry date/time, 
 * schedules, eth allocation per game, token allocation per game, kittiehell 
 * kittie expiration, time durations, distribution percentages e.t.c.
 * The note modifier will log event for each function call.
 * @dev One setter that is called from GameVarAndFeeProxy contract setters
 */
contract GameVarAndFee is Proxied, VarAndFeeNames {

    // Declare DB type variable
    GenericDB public genericDB;

    /// @notice Function called when deployed
    /// @param _genericDB Address of deployed GeneriDB contract
    constructor (GenericDB _genericDB) public {
        setGenericDB(_genericDB);
    }
    
    /// @notice Set genericDB variable to store data in contract
    function setGenericDB(GenericDB _genericDB) public onlyOwner {
        genericDB = _genericDB;
    }

    /// @notice for testing only
    function initialize() external onlyOwner {
        RoleDB(proxy.getContract(CONTRACT_NAME_ROLE_DB)).addRole(CONTRACT_NAME_GAMEVARANDFEE, "super_admin", msg.sender);
    }

    // ----- SETTER ------

    /// @notice Generic Setter for all vars and fees  
    /// @param key hash of Table Name and keyName to store in DB
    /// @param value value of the variable to store
    /// @dev can only be called by Super Admin through proxy
    function setVarAndFee(bytes32 key, uint value) 
    external onlyProxy {
        genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key, value);
    }  

    // ----- GETTERS -------

    // /// @notice Generic Getter
    // function getVarAndFee(string memory keyName) 
    // public view returns(uint) { 
    //     bytes32 key = keccak256(abi.encodePacked(TABLE_NAME, keyName));
    //     return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, key);
    // }
        
    /// @notice Gets the time in future that a game is to be played
    function getFutureGameTime() 
    public view returns(uint) { 
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, FUTURE_GAME_TIME);
    }
    
    /// @notice Gets 2 min alloted time whereby both players must initiate start or forfeit game.
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
    
    /// @notice Gets the farthest time in futre when a game can be schedule
    function getScheduleTimeLimits() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, SCHEDULE_TIME_LIMITS);
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
    
    /// @notice Gets Amount of games allowed per day 
    function getDailyGameAvailability() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, DAILY_GAME_AVAILABILITY);
    }
    
    /// @notice Gets Times duration between each game per day
    function getGameTimes() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, GAME_TIMES);
    }
    
    /// @notice Gets Games per day allowed per address "Games rate limit"
    function getGameLimit() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, GAME_LIMIT);
    }
    
    /// @notice Gets fee paid to lift the limit of the number of games allowed per day, per address
    function getGamesRateLimitFee() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, GAMES_RATE_LIMIT_FEE);
    }
    
    /// @notice Gets Distribution Rates
    function getDistributionRates() 
    public view returns(uint[] memory rates) {
                
        rates[0] = genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, WINNING_KITTIE);
        
        rates[1] = genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, TOP_BETTOR);
        
        rates[2] = genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, SECOND_RUNNER_UP);
        
        rates[3] = genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, OTHER_BETTORS);
        
        rates[4] = genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, ENDOWNMENT);
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

    /// @notice Gets Kittie expiry time in kittieHELL 
    function getKittieExpiry() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, KITTIE_EXPIRY);
    }

    /// @notice Gets honeyPot duration/expiry after game end 
    function getHoneyPotDuration() 
    public view returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE, HONEY_POT_DURATION);
    }

}
