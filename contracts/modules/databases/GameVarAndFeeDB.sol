/**
 * @title GameVarAndFee
 *
 * @author @wafflemakr @hamaad
 *
 */
 
 pragma solidity ^0.5.5;

 import "../proxy/Proxied.sol";
 import "./GenericDB.sol";
 import "../../libs/SafeMath.sol";

 contract GameVarAndFeeDB is Proxied {

    using SafeMath for uint256;

    GenericDB public genericDB;

    constructor (GenericDB _genericDB) public {
        setGenericDB(_genericDB);
    }
    
    function setGenericDB(GenericDB _genericDB) public onlyOwner {
        genericDB = _genericDB;
    }

    function setFutureGameTime(uint _futureGameTime) 
    external onlyContract(CONTRACT_NAME_GAMEVARANDFEE) {
        genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE_DB, keccak256(abi.encodePacked("futureGameTime")), _futureGameTime);
    }

    function getFutureGameTime() 
    external view onlyContract(CONTRACT_NAME_GAMEVARANDFEE)
    returns(uint) {
        return genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE_DB, keccak256(abi.encodePacked("futureGameTime")));
    }

 }