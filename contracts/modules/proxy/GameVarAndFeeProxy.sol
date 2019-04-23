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


    // TODO: rest of setters..//
  
}
