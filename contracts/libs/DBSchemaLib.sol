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


/**
 * @title Database schemas
 * @author @kittieFIGHT @psychoplasma
 */
library DBSchemaLib {

  struct KittyStatus {
    bool dead;      // This is the mortality status of the kitty
    bool playing;   // This is the current game participation status of the kitty
    uint deadAt;    // Timestamp when the kitty is dead.
  }

  struct ProfileSchema {
    uint256 id;
    address owner;
    KittyStatus kittyStatus;
    uint256 cryptokittyId;
    bytes32[4] torMagnetsImagelinks;
    uint256 losses;
    uint256 totalFights;
    uint256 nextFight;
    uint256 listingStartAt;
    uint256 listingEndAt;
    uint256 genes;
    bytes32 description;
  }

  struct FeeLimits {
    uint256 fightFeeLimit;
    uint256 resurrectionFeeLimit;
  }

  struct Fees {
    uint256 paidDate;
    uint256 feeType;
    uint256 expirationDate;
    bool paid;
    FeeLimits feelimits;
  }
}
