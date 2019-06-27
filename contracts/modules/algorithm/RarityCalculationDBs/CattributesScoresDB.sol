pragma solidity ^0.5.5;

import "../../../authority/Owned.sol";

/**
 * @title This contract is a database stroing cattributes and each cattribute's score
 * @author @ziweidream
 */
contract CattributesScoresDB is Owned {
    mapping(string => uint) public CattributesScores;

    /**
     * @author @ziweidream
     * @notice mapping a cattribute with its score
     * @dev this db needs to beupdated periodically. 
     * @dev https://api.cryptokitties.co/cattributes
     * @param _name the cattribute's name 
     * @param _score the cattribute's score 
     */
    function updateCattributesScores(string memory _name, uint _score) public onlyOwner {
        CattributesScores[_name] = _score;
    }
}