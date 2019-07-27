// Only RarityCalculator.sol is deployed. Contracts in /algorithm/RarityCalculationDBs are not deployed.
 // All functions and variables in contracts in the folder RarityCalculationDBs are internal. They are set as public just
 // temporarily for truffle test purpose. (Truffle test cannot carry out internal functions)
 // onlyContract modifier is temporarilly comment out until game manager contract is more defined
// a kittie's gene is stored in ProfileDB, and can be obtained via the function: getKittieAttributes()
/**
 * @title RarityCalculator
 *
 * @author @kittieFIGHT @ola
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

import "../proxy/Proxied.sol";
import "../../authority/Guard.sol";
import "../../libs/SafeMath.sol";
import "./RarityCalculationDBs/Rarity.sol";
import "./RarityCalculationDBs/DefenseLevel.sol";
import "./RarityCalculationDBs/FancyKitties.sol";

/**
 * @title This contract is responsible to calculate the defense level of a kitty
 * within 2 minutes before the game starts
 * @author @ziweidream
 */

contract RarityCalculator is Proxied, Guard, Rarity, DefenseLevel, FancyKitties {
    using SafeMath for uint256;

    /**
     * @author @ziweidream
     * @notice calculate the defense level of a kitty
     * @dev a kitty's defense level is an integer between 1 and 6
     * @param kittieId the kittyID for whom the defense level is calculated
     * @param gene the kitty's gene
     * @return the kitty's defense level
     */
    function getDefenseLevel(uint256 kittieId, uint256 gene)
      public
      //onlyContract(CONTRACT_NAME_GAMMANAGER)
      returns (uint256) {
      getDominantGeneBinary(kittieId, gene);
      binaryToKai(kittieId);
      kaiToCattribute(kittieId);

      uint256 rarity = calculateRarity(kittieId);

      uint256 defenseLevel;

      if (kittieId < 10000) {
          defenseLevel = 6;
      } else if (isFancy(kittieId)) {
          defenseLevel = 5;
      } else if (rarity < defenseLevelLimit.level5Limit) {
          defenseLevel = 6;
      } else if (rarity >= defenseLevelLimit.level5Limit && rarity < defenseLevelLimit.level4Limit) {
          defenseLevel = 5;
      } else if (rarity >= defenseLevelLimit.level4Limit && rarity < defenseLevelLimit.level3Limit) {
          defenseLevel = 4;
      } else if (rarity >= defenseLevelLimit.level3Limit && rarity < defenseLevelLimit.level2Limit) {
          defenseLevel = 3;
      } else if (rarity >= defenseLevelLimit.level2Limit && rarity < defenseLevelLimit.level1Limit) {
          defenseLevel = 2;
      } else if (rarity >= defenseLevelLimit.level1Limit) {
          defenseLevel = 1;
      } else {
          // if all conditions above are not met for some unprecitable reason,
          // then default to 1 so that the game can continue
          defenseLevel = 1;
      }

      emit OriginalDefenseLevelCalculated(kittieId, defenseLevel);

      assert(defenseLevel > 0);
      return defenseLevel;
    }

    function isFancy(uint256 _kittieId)
        public // temporarily set as public just for truffle test purpose
        // internal
        view
        returns(bool)
    {
        string memory fancyName = FancyKittiesList[_kittieId];
        bytes memory fancyNameBytes = bytes(fancyName);
        if (fancyNameBytes.length != 0) {
            // fancyName is NOT an empty string
            return true;
        }

        return false;
    }

    event OriginalDefenseLevelCalculated(uint256 indexed _kittieId, uint256 _originalDefenseLevel);
}