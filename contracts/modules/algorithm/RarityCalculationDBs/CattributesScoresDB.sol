pragma solidity ^0.5.5;

import "../../proxy/Proxied.sol";
import "../../../authority/Guard.sol";

/**
 * @title This contract is a database stroing cattributes and each cattribute's score
 * @author @ziweidream
 */
contract CattributesScoresDB is Proxied, Guard {
    /* This is the totoal number of all the kitties on CryptoKitties */
    uint256 totalKitties;

    mapping(string => uint) public CattributesScores;

    function updateTotalKitties(uint256 _totalKitties)
        public
        onlySuperAdmin
    {
        totalKitties = _totalKitties;
    }

    /**
     * @author @ziweidream
     * @notice mapping a cattribute with its score
     * @dev this db needs to beupdated periodically.
     * @dev https://api.cryptokitties.co/cattributes
     * @param _name the cattribute's name
     * @param _score the cattribute's score
     */
    function updateCattributesScores(string memory _name, uint _score)
        public  // temporarily set as public just for truffle test purpose
        // internal
        onlySuperAdmin
    {
        CattributesScores[_name] = _score;
    }
}