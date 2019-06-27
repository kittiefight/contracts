/**
 * @title Betting
 *
 * @author @wafflemakr
 *
 */
//modifier class (DSAuth )
//Event class ( DSNote )
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
pragma solidity ^0.5.5;

import '../proxy/Proxied.sol';
import './HitsResolveAlgo.sol';
import '../databases/GameManagerDB.sol';

contract Betting is Proxied {

    //Contract Variables
    GameManagerDB public gameManagerDB;
    HitsResolve public hitsResolve;


    /**
    * @dev Sets related contracts
    * @dev Can be called only by the owner of this contract
    */
    function initialize() external onlyOwner {

        //TODO: Check what other contracts do we need
        gameManagerDB = GameManagerDB(proxy.getContract(CONTRACT_NAME_GAMEMANAGER_DB));
        hitsResolve = HitsResolve(proxy.getContract(CONTRACT_NAME_HITSRESOLVE));
    }

    function startGame(uint randomNum)
        external
        onlyContract(CONTRACT_NAME_GAMEMANAGER)
        returns(uint[] memory)
    {
        //return FightMap
    }

    function bet(uint gameId, uint randomNum, uint betAmount)
        external
        onlyContract(CONTRACT_NAME_GAMEMANAGER)
    {
        //get last five bets from GameManagerDB
        //check if bet is greater than previous 5 bets
        
        storeRandomSeed(randomNum);

        // prevent supporting address from betting on other side already, done in GameManagerDB
        // calls endowment api : send KTY token fee to endowment fund, done in GameManager

        //return (attackHash, attackType);
    }

    function storeRandomSeed(uint randomNum) internal{
        //uint currentRandom = hitsResolve.calculateCurrentRandom(randomNum);
    }

}
