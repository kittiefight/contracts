pragma solidity ^0.5.5;

import "../../proxy/Proxied.sol";
import "../../../authority/Guard.sol";

/**
 * @title This contract is a database storing a gene in kai notation and its corresponding cattribute
 * @author @ziweidream
 */

contract KaiToCattributesDB is Proxied, Guard {

    mapping(string => mapping(string => string)) public cattributes;

    /**
     * @author @ziweidream
     * @notice mapping a gene in kai notation to its corresponding cattribute
     * @dev https://github.com/openblockchains/programming-cryptocollectibles/blob/master/02_genereader.md
     * @param _type type of cattributes in small letters
     * @param _kai kai notation of a gene in small letters
     * @param _cattribute the corresponding cattribute of a gene in kai notation, in small letters
     */
    function updateCattributes(string memory _type, string memory _kai, string memory _cattribute)
        public // temporarily set as public just for truffle test purpose
        //internal
        onlySuperAdmin
    {
        cattributes[_type][_kai] = _cattribute;
    }
}