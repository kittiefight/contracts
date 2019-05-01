/**
 * @title GameVarAndFee
 *
 * @author @wafflemakr @hamaad
 *
 */

pragma solidity ^0.5.5;

import "./ProxyBase.sol";
import '../../authority/Guard.sol';
import '../../misc/VarAndFeeNames.sol';
import '../../interfaces/IGameVarAndFee.sol';

/**
 * @title Contract to set Game vars and fees through Proxy
 * @dev setters can only be called by SuperAdmin Role
 */
contract GameVarAndFeeProxy is ProxyBase, Guard, VarAndFeeNames {

    /**
        @notice Setters for GameVarAndFee using Guard modifiers with Super Admin Role.
        @dev Using interface instead of actual contract to avoid inheritance problems with Proxy

    */

    function setFutureGameTime(uint value) 
    external onlySuperAdmin { 
        IGameVarAndFee(getContract(CONTRACT_NAME_GAMEVARANDFEE)).setVarAndFee(FUTURE_GAME_TIME, value);
    }

    function setGamePrestart(uint value) 
    external onlySuperAdmin{ 
        IGameVarAndFee(getContract(CONTRACT_NAME_GAMEVARANDFEE)).setVarAndFee(GAME_PRESTART, value);
    }

    function setGameDuration(uint value) 
    external onlySuperAdmin{ 
        IGameVarAndFee(getContract(CONTRACT_NAME_GAMEVARANDFEE)).setVarAndFee(GAME_DURATION, value);
    }

    function setKittieHellExpiration(uint value) 
    external onlySuperAdmin{ 
        IGameVarAndFee(getContract(CONTRACT_NAME_GAMEVARANDFEE)).setVarAndFee(KITTIE_HELL_EXPIRATION, value);
    }

    function setHonyPotExpiration(uint value) 
    external  onlySuperAdmin{
        IGameVarAndFee(getContract(CONTRACT_NAME_GAMEVARANDFEE)).setVarAndFee(HONEY_POT_EXPIRATION,value);
    }

    function setScheduleTimeLimits(uint value) 
    external onlySuperAdmin{ 
        IGameVarAndFee(getContract(CONTRACT_NAME_GAMEVARANDFEE)).setVarAndFee(SCHEDULE_TIME_LIMITS, value);
    }

    function setTokenPerGame(uint value) 
    external onlySuperAdmin{ 
        IGameVarAndFee(getContract(CONTRACT_NAME_GAMEVARANDFEE)).setVarAndFee(TOKENS_PER_GAME, value);
    }

    function setEtherPerGame(uint value) 
    external onlySuperAdmin{ 
        IGameVarAndFee(getContract(CONTRACT_NAME_GAMEVARANDFEE)).setVarAndFee(ETH_PER_GAME, value);
    }

    function setDailyGameAvailAbility(uint value) 
    external onlySuperAdmin{ 
        IGameVarAndFee(getContract(CONTRACT_NAME_GAMEVARANDFEE)).setVarAndFee(DAILY_GAME_AVAILABILITY, value);
    }

    function setGameTimes(uint value) 
    external onlySuperAdmin{ 
        IGameVarAndFee(getContract(CONTRACT_NAME_GAMEVARANDFEE)).setVarAndFee(GAME_TIMES, value);
    }

    function setGameLimit(uint value) 
    external onlySuperAdmin{ 
        IGameVarAndFee(getContract(CONTRACT_NAME_GAMEVARANDFEE)).setVarAndFee(GAME_LIMIT, value);
    }

    function setGamesRateLimitFee(uint value) 
    external onlySuperAdmin{ 
        IGameVarAndFee(getContract(CONTRACT_NAME_GAMEVARANDFEE)).setVarAndFee(GAMES_RATE_LIMIT_FEE, value);
    }

    function setWinningKittie(uint value) 
    external onlySuperAdmin{ 
        IGameVarAndFee(getContract(CONTRACT_NAME_GAMEVARANDFEE)).setVarAndFee(WINNING_KITTIE, value);
    }

    function setTopBettor(uint value) 
    external onlySuperAdmin{ 
        IGameVarAndFee(getContract(CONTRACT_NAME_GAMEVARANDFEE)).setVarAndFee(TOP_BETTOR, value);
    }

    function setSecondRunnerUp(uint value) 
    external onlySuperAdmin{ 
        IGameVarAndFee(getContract(CONTRACT_NAME_GAMEVARANDFEE)).setVarAndFee(SECOND_RUNNER_UP, value);
    }

    function setOtherBettor(uint value) 
    external onlySuperAdmin{ 
        IGameVarAndFee(getContract(CONTRACT_NAME_GAMEVARANDFEE)).setVarAndFee(OTHER_BETTORS, value);
    }
      
    function setEndowment(uint value) 
    external onlySuperAdmin{ 
        IGameVarAndFee(getContract(CONTRACT_NAME_GAMEVARANDFEE)).setVarAndFee(ENDOWNMENT, value);
    }  

    function setTicketFee(uint value) 
    external onlySuperAdmin{ 
        IGameVarAndFee(getContract(CONTRACT_NAME_GAMEVARANDFEE)).setVarAndFee(TICKET_FEE, value);
    }
    
    function setBettingFee(uint value) 
    external onlySuperAdmin{ 
        IGameVarAndFee(getContract(CONTRACT_NAME_GAMEVARANDFEE)).setVarAndFee(BETTING_FEE, value);
    }

    function setKittieRedemptionFee(uint value) 
    external onlySuperAdmin{ 
        IGameVarAndFee(getContract(CONTRACT_NAME_GAMEVARANDFEE)).setVarAndFee(KITTIE_REDEMPTION_FEE, value);
    } 

    function setKittieExpiry(uint value) 
    external onlySuperAdmin{ 
        IGameVarAndFee(getContract(CONTRACT_NAME_GAMEVARANDFEE)).setVarAndFee(KITTIE_EXPIRY, value);
    }

    function setHonyPotDuration(uint value) 
    external onlySuperAdmin{ 
        IGameVarAndFee(getContract(CONTRACT_NAME_GAMEVARANDFEE)).setVarAndFee(HONEY_POT_DURATION, value);
    } 


}
