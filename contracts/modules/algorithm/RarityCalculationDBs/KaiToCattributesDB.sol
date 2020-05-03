pragma solidity ^0.5.5;

import "../../proxy/Proxied.sol";
import "../../../authority/Guard.sol";

/**
 * @title This contract is a database storing a gene in kai notation and its corresponding cattribute
 * @author @ziweidream @Xale
 */

contract KaiToCattributesDB is Proxied, Guard {

    mapping(string => mapping(bytes1 => string)) public cattributes;

    /**
     * @author @ziweidream @Xale
     * @notice mapping a gene in kai notation to its corresponding cattribute
     * @dev https://github.com/openblockchains/programming-cryptocollectibles/blob/master/02_genereader.md
     * @param _type type of cattributes in small letters
     * @param _kai kai notation of a gene in small letters
     * @param _cattribute the corresponding cattribute of a gene in kai notation, in small letters
     */

    uint256 j = 0; //How many types already allocated

    uint cattribute = 0;

    string[10] types = ["body", "pattern", "coloreyes",
                        "eyes", "color1", "color2", "color3",
                        "wild", "mouth", "environment" ];

    string keys = "123456789abcdefghijkmnopqrstuvwx";

    function updateCattributes(bytes32[] memory _cattribute, uint _noOfTypes)
        public
        onlySuperAdmin
    {   
        for(uint i=j; i<j+_noOfTypes; i++){
            for(uint k=0; k<32; k++){
                cattributes[types[i]][stringToBytes1(keys,32+k)] = bytes32ToStr(_cattribute[cattribute]);
                cattribute ++;
            }
        }
        j = j + _noOfTypes;
        cattribute = 0;
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

    function stringToBytes1(string memory source, uint place) 
        internal pure 
        returns (bytes1 result) 
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, place))
        }
    }

}