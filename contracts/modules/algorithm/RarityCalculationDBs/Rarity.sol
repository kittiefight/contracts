pragma solidity ^0.5.5;

import "../../../authority/Owned.sol";
import "./KittiesCattributesDB.sol";
import "./CattributesScoresDB.sol";

/**
 * @title This contract is responsible to calculate the rarity level of a kitty 
 * @author @ziweidream
 */

contract Rarity is Owned, KittiesCattributesDB, CattributesScoresDB {
    /* This is the totoal number of all the kitties on CryptoKitties */
    uint totalKitties;

    /**
     * @author @ziweidream
     * @notice calculate a kitty's rarity based on its cattributes
     * @return the rarity of a kittie as an integer
     */
    function updateTotalKitties(uint _totalKitties) public onlyOwner {
        totalKitties = _totalKitties;
    }

    function calculateRarity(uint kittieId) public view onlyOwner returns (uint rarity) {
      rarity = 100000000 * (CattributesScores[kittiesDominantCattributes[kittieId][0]] 
                                             + CattributesScores[kittiesDominantCattributes[kittieId][1]] 
                                             + CattributesScores[kittiesDominantCattributes[kittieId][2]] 
                                             + CattributesScores[kittiesDominantCattributes[kittieId][3]] 
                                             + CattributesScores[kittiesDominantCattributes[kittieId][4]] 
                                             + CattributesScores[kittiesDominantCattributes[kittieId][5]] 
                                             + CattributesScores[kittiesDominantCattributes[kittieId][6]] 
                                             + CattributesScores[kittiesDominantCattributes[kittieId][8]]) / totalKitties; 
    }
}