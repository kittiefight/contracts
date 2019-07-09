pragma solidity ^0.5.5;

import "../../proxy/Proxied.sol";
import "./KaiToCattributesDB.sol";
import "./KaiValueDB.sol";
import "../../databases/ProfileDB.sol";
import "../../../interfaces/IContractManager.sol";

/**
 * @title This contract converts a kitty's genes into binary, kai notation, and cattributes
 * and stores them in mappings
 * @author @ziweidream
 */

contract KittiesCattributesDB is Proxied, KaiToCattributesDB, KaiValueDB {
    
    string[] public dominantGeneBinary;
    mapping(uint => string[]) kittiesDominantGeneBinary;
    string[] public dominantGeneKai;
    mapping(uint => string[]) kittiesDominantGeneKai;
    string[] public dominantCattributes;
    mapping(uint => string[]) kittiesDominantCattributes;

    /**
     * @author @ziweidream
     * @notice converts kai notation to its corresponding cattribute
     */
    function kaiToCattribute(uint kittieId) 
      public  
      //onlyContract(CONTRACT_NAME_GAMEMANAGER) 
    {
       dominantCattributes.push(cattributes['body'][kittiesDominantGeneKai[kittieId][0]]);
       dominantCattributes.push(cattributes['pattern'][kittiesDominantGeneKai[kittieId][1]]);
       dominantCattributes.push(cattributes['coloreyes'][kittiesDominantGeneKai[kittieId][2]]);
       dominantCattributes.push(cattributes['eyes'][kittiesDominantGeneKai[kittieId][3]]);
       dominantCattributes.push(cattributes['color1'][kittiesDominantGeneKai[kittieId][4]]);
       dominantCattributes.push(cattributes['color2'][kittiesDominantGeneKai[kittieId][5]]);
       dominantCattributes.push(cattributes['color3'][kittiesDominantGeneKai[kittieId][6]]);
       dominantCattributes.push(cattributes['wild'][kittiesDominantGeneKai[kittieId][7]]);
       dominantCattributes.push(cattributes['mouth'][kittiesDominantGeneKai[kittieId][8]]);
       dominantCattributes.push(cattributes['environment'][kittiesDominantGeneKai[kittieId][9]]);
       
       kittiesDominantCattributes[kittieId] = dominantCattributes;
    }
   
   /**
     * @author @ziweidream
     * @notice converts binary to its corresponding kai notation
     * @notice only dominant genes are kept since kitties only demonstrate cattributes from dominant genes.
     */
   function binaryToKai(uint kittieId) 
     public
     //onlyContract(CONTRACT_NAME_GAMEMANAGER) 
     {
       dominantGeneKai.push(kaiValue[kittiesDominantGeneBinary[kittieId][0]]);
       dominantGeneKai.push(kaiValue[kittiesDominantGeneBinary[kittieId][1]]);
       dominantGeneKai.push(kaiValue[kittiesDominantGeneBinary[kittieId][2]]);
       dominantGeneKai.push(kaiValue[kittiesDominantGeneBinary[kittieId][3]]);
       dominantGeneKai.push(kaiValue[kittiesDominantGeneBinary[kittieId][4]]);
       dominantGeneKai.push(kaiValue[kittiesDominantGeneBinary[kittieId][5]]);
       dominantGeneKai.push(kaiValue[kittiesDominantGeneBinary[kittieId][6]]);
       dominantGeneKai.push(kaiValue[kittiesDominantGeneBinary[kittieId][7]]);
       dominantGeneKai.push(kaiValue[kittiesDominantGeneBinary[kittieId][8]]);
       dominantGeneKai.push(kaiValue[kittiesDominantGeneBinary[kittieId][9]]);
       
       kittiesDominantGeneKai[kittieId] = dominantGeneKai;
       
   }
   
   /**
     * @author @ziweidream
     * @notice converts an integer to its binary
     * @param n the integer to be converted
     * @return the binary
     */
   function toBinaryString(uint n) public pure returns (string memory) {

        bytes memory output = new bytes(240);

        for (uint i = 0; i < 240; i++) {
            output[239 - i] = (n % 2 == 1) ? byte("1") : byte("0");
            n /= 2;
        }

        return string(output);
    }
    
    /**
     * @author @ziweidream
     * @notice converts the gene in uint of a kitty to binary. 
     * @notice only dominant genes are kept since kitties only demonstrate cattributes from dominant genes.
     */
    function getDominantGeneBinary(uint kittieId) 
      public
      //onlyContract(CONTRACT_NAME_GAMEMANAGER) 
     {

        // gene is temporarily hard-coded for kitty 1001, which is used in Truffle test. 
        // gene will be obtained from ProfileDB.
        // gene will be updated to a variable after ProfileDB incorporates gene 
        // to functions addKittie() and setKittieAttributes, and possibly
        // a new function getGene()
        uint gene = 512955438081049600613224346938352058409509756310147795204209859701881294;

        string memory geneBinary = toBinaryString(gene);
        dominantGeneBinary.push(getSlice(236, 240, geneBinary));
        dominantGeneBinary.push(getSlice(216, 220, geneBinary));
        dominantGeneBinary.push(getSlice(196, 200, geneBinary));
        dominantGeneBinary.push(getSlice(176, 180, geneBinary));
        dominantGeneBinary.push(getSlice(156, 160, geneBinary));
        dominantGeneBinary.push(getSlice(136, 140, geneBinary));
        dominantGeneBinary.push(getSlice(116, 120, geneBinary));
        dominantGeneBinary.push(getSlice(96, 100, geneBinary));
        dominantGeneBinary.push(getSlice(76, 80, geneBinary));
        dominantGeneBinary.push(getSlice(56, 60, geneBinary));
        kittiesDominantGeneBinary[kittieId] = dominantGeneBinary;
    }

  
    /**
     * @author @ziweidream
     * @notice gets slice of a string
     */
    function getSlice(uint256 begin, uint256 end, string memory text) public pure returns (string memory) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i=0;i<=end-begin;i++){
            a[i] = bytes(text)[i+begin-1];
        }
        return string(a);    
    }
}