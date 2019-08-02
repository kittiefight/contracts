pragma solidity ^0.5.5;

/**
 * @title This contract is a database stroing the kittieId and name of valuable fancy cats
 * @author @ziweidream
 */
contract FancyKitties {

    mapping(uint256 => string) internal FancyKittiesList;

    /**
     * @author @ziweidream
     * @notice mapping of a fancy kittie's kittieId to its fancy name
     * @dev this db needs to beupdated periodically.
     * @param _kittieId the kittieId of the fancy kittie
     * @param _name the fancy name of the fancy kittie
     */
    function updateFancyKittiesList(uint256 _kittieId, string memory _name)
        public  // temporarily set as public just for truffle test purpose
        // internal
        //onlySuperAdmin
    {
        FancyKittiesList[_kittieId] = _name;
    }
}