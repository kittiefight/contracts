pragma solidity ^0.5.5;

import "../../../libs/SafeMath.sol";
import "../../proxy/Proxied.sol";
import "../../../authority/Guard.sol";
import "./KaiToCattributesDB.sol";
import "./KaiValueDB.sol";
import "../../databases/ProfileDB.sol";
import "../../../interfaces/IContractManager.sol";

/**
 * @title This contract converts a kitty's genes into binary, kai notation, and cattributes
 * and stores them in mappings
 * @author @ziweidream
 */

contract KittiesCattributesDB is Proxied, Guard, KaiToCattributesDB, KaiValueDB {
    using SafeMath for uint256;

    mapping(uint256 => string[]) public kittiesDominantGeneBinary;
    mapping(uint256 => bytes1[]) public kittiesDominantGeneKai;
    mapping(uint256 => string[]) public kittiesDominantCattributes;

    /**
     * @author @ziweidream
     * @notice converts kai notation to its corresponding cattribute
     */
    function kaiToCattribute(uint256 kittieId)
      public
    {
       kittiesDominantCattributes[kittieId].push(cattributes['body'][kittiesDominantGeneKai[kittieId][0]]);
       kittiesDominantCattributes[kittieId].push(cattributes['pattern'][kittiesDominantGeneKai[kittieId][1]]);
       kittiesDominantCattributes[kittieId].push(cattributes['coloreyes'][kittiesDominantGeneKai[kittieId][2]]);
       kittiesDominantCattributes[kittieId].push(cattributes['eyes'][kittiesDominantGeneKai[kittieId][3]]);
       kittiesDominantCattributes[kittieId].push(cattributes['color1'][kittiesDominantGeneKai[kittieId][4]]);
       kittiesDominantCattributes[kittieId].push(cattributes['color2'][kittiesDominantGeneKai[kittieId][5]]);
       kittiesDominantCattributes[kittieId].push(cattributes['color3'][kittiesDominantGeneKai[kittieId][6]]);
       kittiesDominantCattributes[kittieId].push(cattributes['wild'][kittiesDominantGeneKai[kittieId][7]]);
       kittiesDominantCattributes[kittieId].push(cattributes['mouth'][kittiesDominantGeneKai[kittieId][8]]);
       kittiesDominantCattributes[kittieId].push(cattributes['environment'][kittiesDominantGeneKai[kittieId][9]]);
    }
  
   /**
     * @author @ziweidream
     * @notice converts binary to its corresponding kai notation
     * @notice only dominant genes are kept since kitties only demonstrate cattributes from dominant genes.
     */
   function binaryToKai(uint256 kittieId)
     public  // temporarily set as public just for truffle test purpose
     //internal
     {
       kittiesDominantGeneKai[kittieId].push(kaiValue[kittiesDominantGeneBinary[kittieId][0]]);
       kittiesDominantGeneKai[kittieId].push(kaiValue[kittiesDominantGeneBinary[kittieId][1]]);
       kittiesDominantGeneKai[kittieId].push(kaiValue[kittiesDominantGeneBinary[kittieId][2]]);
       kittiesDominantGeneKai[kittieId].push(kaiValue[kittiesDominantGeneBinary[kittieId][3]]);
       kittiesDominantGeneKai[kittieId].push(kaiValue[kittiesDominantGeneBinary[kittieId][4]]);
       kittiesDominantGeneKai[kittieId].push(kaiValue[kittiesDominantGeneBinary[kittieId][5]]);
       kittiesDominantGeneKai[kittieId].push(kaiValue[kittiesDominantGeneBinary[kittieId][6]]);
       kittiesDominantGeneKai[kittieId].push(kaiValue[kittiesDominantGeneBinary[kittieId][7]]);
       kittiesDominantGeneKai[kittieId].push(kaiValue[kittiesDominantGeneBinary[kittieId][8]]);
       kittiesDominantGeneKai[kittieId].push(kaiValue[kittiesDominantGeneBinary[kittieId][9]]);
   }
  
   /**
     * @author @ziweidream
     * @notice converts an integer to its binary
     * @param n the integer to be converted
     * @return the binary
     */
   function toBinaryString(uint256 n) public pure returns (string memory) {

        bytes memory output = new bytes(240);

        for (uint256 i = 0; i < 240; i++) {
            output[239 - i] = (n % 2 == 1) ? byte("1") : byte("0");
            n = n.div(2);
        }

        return string(output);
    }
  
    /**
     * @author @ziweidream
     * @notice converts the gene in uint of a kitty to binary.
     * @notice only dominant genes are kept since kitties only demonstrate cattributes from dominant genes.
     */
    function getDominantGeneBinary(uint256 kittieId, uint256 gene)
      public
     {
        string memory geneBinary = toBinaryString(gene);
        kittiesDominantGeneBinary[kittieId].push(getSlice(236, 240, geneBinary));
        kittiesDominantGeneBinary[kittieId].push(getSlice(216, 220, geneBinary));
        kittiesDominantGeneBinary[kittieId].push(getSlice(196, 200, geneBinary));
        kittiesDominantGeneBinary[kittieId].push(getSlice(176, 180, geneBinary));
        kittiesDominantGeneBinary[kittieId].push(getSlice(156, 160, geneBinary));
        kittiesDominantGeneBinary[kittieId].push(getSlice(136, 140, geneBinary));
        kittiesDominantGeneBinary[kittieId].push(getSlice(116, 120, geneBinary));
        kittiesDominantGeneBinary[kittieId].push(getSlice(96, 100, geneBinary));
        kittiesDominantGeneBinary[kittieId].push(getSlice(76, 80, geneBinary));
        kittiesDominantGeneBinary[kittieId].push(getSlice(56, 60, geneBinary));
    }

    /**
     * @author @ziweidream
     * @notice gets slice of a string
     */
    function getSlice(uint256 begin, uint256 end, string memory text)
        public
        pure
        returns (string memory) {
        bytes memory a = new bytes(end.sub(begin).add(1));
        for(uint256 i=0; i<=end.sub(begin); i++){
            a[i] = bytes(text)[i.add(begin).sub(1)];
        }
        return string(a);
    }
}