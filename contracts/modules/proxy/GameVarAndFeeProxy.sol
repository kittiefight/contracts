pragma solidity ^0.5.5;

import "../../GameVarAndFee.sol";
//import '../../authority/Guard.sol';
import "./ProxyBase.sol";

contract GameVarAndFeeProxy is ProxyBase {

    function setVarAndFee(string memory keyName, uint value)
    public{
        GameVarAndFee(addressOfGameVarAndFee()).setVarAndFee(keyName, value);
    }
}
