
pragma solidity ^0.5.5;


import "./ProxyBase.sol";
import '../../authority/Guard.sol';
import "../../GameVarAndFee.sol";
import '../../misc/VarAndFeeNames.sol';

contract GameVarAndFeeProxy is ProxyBase, Guard, VarAndFeeNames {

    // Or just one setter?
    // function setVarAndFee(string memory keyName, uint value)
    // public{
    //     GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(keyName, value);
    // } 

    // --------   
    
    function setFutureGameTime(uint value) 
    external onlySuperAdmin { 
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(FUTURE_GAME_TIME, value);
    }

    function setGamePrestart(uint value) 
    external onlySuperAdmin{ 
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(GAME_PRESTART, value);
    }

    function setGameDuration(uint value) 
    external onlySuperAdmin{ 
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(GAME_DURATION, value);
    }

    function setKittieHellExpiration(uint value) 
    external onlySuperAdmin{ 
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(KITTIE_HELL_EXPIRATION, value);
    }
    function setHonyPotExpiration(uint value) 
    external  onlySuperAdmin{
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(HONEY_POT_EXPIRATION,value);
    }

     function setScheduleTimeLimits(uint value) 
    external onlySuperAdmin{ 
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(SCHEDULE_TIME_LIMITS, value);
    }
  function setTokenPerGame(uint value) 
    external onlySuperAdmin{ 
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(TOKENS_PER_GAME, value);
    }
function setEtherPerGame(uint value) 
    external onlySuperAdmin{ 
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(ETH_PER_GAME, value);
    }


function setDailyGameAvailAbility(uint value) 
    external onlySuperAdmin{ 
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(DAILY_GAME_AVAILABILITY, value);
    }

function setGameTimes(uint value) 
    external onlySuperAdmin{ 
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(GAME_TIMES, value);
    }

function setGameLimit(uint value) 
    external onlySuperAdmin{ 
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(GAME_LIMIT, value);
    }

function setGamesRateLimitFee(uint value) 
    external onlySuperAdmin{ 
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(GAMES_RATE_LIMIT_FEE, value);
    }

function setWinningKittie(uint value) 
    external onlySuperAdmin{ 
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(WINNING_KITTIE, value);
    }

function setTopBettor(uint value) 
    external onlySuperAdmin{ 
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(TOP_BETTOR, value);
    }

function setSecondRunnerUp(uint value) 
    external onlySuperAdmin{ 
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(SECOND_RUNNER_UP, value);
    }


function setOtherBettor(uint value) 
    external onlySuperAdmin{ 
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(OTHER_BETTORS, value);
    }
      
 function setEndowment(uint value) 
    external onlySuperAdmin{ 
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(ENDOWNMENT, value);
    }     
 function setTicketFee(uint value) 
    external onlySuperAdmin{ 
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(TICKET_FEE, value);
    }
function setBettingFee(uint value) 
    external onlySuperAdmin{ 
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(BETTING_FEE, value);
    }

function setKittieRedemptionFee(uint value) 
    external onlySuperAdmin{ 
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(KITTIE_REDEMPTION_FEE, value);
    } 
function setKittieExpiry(uint value) 
    external onlySuperAdmin{ 
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(KITTIE_EXPIRY, value);
    }   
function setHonyPotDuration(uint value) 
    external onlySuperAdmin{ 
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(HONEY_POT_DURATION, value);
    } 




    // TODO: rest of setters..//
  
}
