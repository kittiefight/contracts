/**
 * @title CronJob
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

import "./modules/proxy/Proxied.sol";
import "./authority/Guard.sol";
import "./modules/kittieHELL/KittieHELL.sol";
import "./modules/databases/KittieHellDB.sol";


contract CronJob is Proxied, Guard {

    // mock variables and functions for testing purpose
    KittieHELL public kittieHell;
    KittieHellDB public kittieHellDB;

    function setKittieHell(KittieHELL _kittieHell) public onlyOwner {
        kittieHell = KittieHELL(_kittieHell);
    }

    function setKittieHellDB(KittieHellDB _kittieHellDB) public onlyOwner {
        kittieHellDB = KittieHellDB(_kittieHellDB);
    }

    function killKitty(uint256 _kittyID)
    public
    returns (bool) {
        return kittieHell.killKitty(_kittyID);
    }

    function releaseKitty(uint256 _kittyID)
        public
    returns (bool) {
        return kittieHell.releaseKitty(_kittyID);
    }

    function becomeGhost(uint256 _kittyID)
        public
    returns (bool) {
        return kittieHell.becomeGhost(_kittyID);

    }

    function removeGhostFromHell(uint256 _id)
        public
    returns (bool) {
        return kittieHellDB.removeGhostFromHell(_id);
    }
}
