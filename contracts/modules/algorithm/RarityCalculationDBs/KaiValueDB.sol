pragma solidity ^0.5.5;

import "../../proxy/Proxied.sol";
import "../../../authority/Guard.sol";

/**
 * @title This contract is a database stroing a cryptokittie's gene in binary
 * and its correspoinding kai notation
 * @author @ziweidream
 */

contract KaiValueDB is Proxied, Guard {
    
     mapping(string => bytes1) public kaiValue;

     /**
     * @author @ziweidream
     * @notice mapping a gene in binary with its kai notation
     */
     function fillKaiValue()
        public
        onlySuperAdmin
      {
        kaiValue['00000'] = "1";
        kaiValue['00001'] = "2";
        kaiValue['00010'] = "3";
        kaiValue['00011'] = "4";
        kaiValue['00100'] = "5";
        kaiValue['00101'] = "6";
        kaiValue['00110'] = "7";
        kaiValue['00111'] = "8";
        kaiValue['01000'] = "9";
        kaiValue['01001'] = "a";
        kaiValue['01010'] = "b";
        kaiValue['01011'] = "c";
        kaiValue['01100'] = "d";
        kaiValue['01101'] = "e";
        kaiValue['01110'] = "f";
        kaiValue['01111'] = "g";
        kaiValue['10000'] = "h";
        kaiValue['10001'] = "i";
        kaiValue['10010'] = "j";
        kaiValue['10011'] = "k";
        kaiValue['10100'] = "m";
        kaiValue['10101'] = "n";
        kaiValue['10110'] = "o";
        kaiValue['10111'] = "p";
        kaiValue['11000'] = "q";
        kaiValue['11001'] = "r";
        kaiValue['11010'] = "s";
        kaiValue['11011'] = "t";
        kaiValue['11100'] = "u";
        kaiValue['11101'] = "v";
        kaiValue['11110'] = "w";
        kaiValue['11111'] = "x";
    
   }
}