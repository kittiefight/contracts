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
     * @author @ziweidream @Xale
     * @notice mapping a cattribute with its score
     * @dev this db needs to beupdated periodically.
     * @dev https://api.cryptokitties.co/cattributes
     * @param _name the cattribute's name
     * @param _score the cattribute's score
     */
    function updateCattributesScores(bytes32[] memory _name, uint[] memory _score)
        public
        onlySuperAdmin
    {
        for(uint i=0; i<_name.length; i++)
        {
            CattributesScores[bytes32ToStr(_name[i])] = _score[i];
        }
    }



    function bytes32ToStr(bytes32 _bytes32)
        internal pure
        returns (string memory)
    {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}
