/**
 * @title GameVarAndFee
 *
 * @author @wafflemakr @hamaad
 *
 */

pragma solidity ^0.5.5;

/**
 * @title Interface to use in GameVarAndFeeProxy to avoid inheritance problems
 */
interface IGameVarAndFee {    
    function setVarAndFee(bytes32 key, uint value) external;    

}
