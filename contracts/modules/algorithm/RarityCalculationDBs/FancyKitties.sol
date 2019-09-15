pragma solidity ^0.5.5;

import "../../proxy/Proxied.sol";
import "../../../authority/Guard.sol";

/**
 * @title This contract is a database stroing the kittieId and name of valuable fancy cats
 * @author @ziweidream @Xale
 */
contract FancyKitties is Proxied, Guard {

    mapping(uint256 => string) internal FancyKittiesList;

    // the file /test/sourceData/FancyKitties.js contains complete data set to fill in this db
    /**
     * @author @ziweidream @Xale
     * @notice mapping of a fancy kittie's kittieId to its fancy name
     * @dev this db needs to beupdated periodically.
     * @param _kittieId the kittieId of the fancy kittie
     * @param _name the fancy name of the fancy kittie
     */
    function updateFancyKittiesList(uint256[] memory _kittieId, bytes32[] memory _name, uint256[] memory _nameLength)
        public
        onlySuperAdmin
    {   
        for(uint i=0; i<_nameLength.length; i++){
            for(uint j=0; j<_nameLength[i]; j++){
                FancyKittiesList[_kittieId[j]] = bytes32ToStr(_name[i]);
            }
        }
    }

    function bytes32ToStr(bytes32 _bytes32)
        internal 
        returns (string memory)
    {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

}