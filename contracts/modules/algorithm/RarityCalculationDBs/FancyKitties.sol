pragma solidity ^0.5.5;

import "../../proxy/Proxied.sol";
import "../../../authority/Guard.sol";

/**
 * @title This contract is a database stroing the kittieId and name of valuable fancy cats
 * @author @ziweidream
 */
contract FancyKitties is Proxied, Guard {

    mapping(uint256 => string) internal FancyKittiesList;

    // the file /test/sourceData/FancyKitties.js contains complete data set to fill in this db
    /**
     * @author @ziweidream
     * @notice mapping of a fancy kittie's kittieId to its fancy name
     * @dev this db needs to beupdated periodically.
     * @param _kittieId the kittieId of the fancy kittie
     * @param _name the fancy name of the fancy kittie
     */
    function updateFancyKittiesList(uint256 _kittieId, string memory _name)
        public
        onlySuperAdmin
    {
        FancyKittiesList[_kittieId] = _name;
    }
}