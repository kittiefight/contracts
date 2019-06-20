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

    string constant TABLE_NAME = "GameVarAndFeeTable";

    GenericDB public genericDB;

    constructor (GenericDB _genericDB) public {
        setGenericDB(_genericDB);
    }
    
    function setGenericDB(GenericDB _genericDB) public onlyOwner {
        genericDB = _genericDB;
    }

    // --- SETTER --- 

    /// @notice Sets the time in future that a game is to be played
    /// @dev check if only one setter function can be implemented
    function setVar(string calldata keyName, uint value) 
    external onlyContract(CONTRACT_NAME_GAMEVARANDFEE) {
        bytes32 key = keccak256(abi.encodePacked(TABLE_NAME, keyName));
        genericDB.setUintStorage(CONTRACT_NAME_GAMEVARANDFEE_DB, key, value);
    }

    function getVar(string memory keyName)
    public view {
        bytes32 key = keccak256(abi.encodePacked(TABLE_NAME, keyName));
        genericDB.getUintStorage(CONTRACT_NAME_GAMEVARANDFEE_DB, key);
    }

 }