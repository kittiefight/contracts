/**
 * @title GameVarAndFee
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

pragma solidity 0.4.21;

import "./interfaces/INTAllContracts.sol";
import "./interfaces/INTContractManager.sol";


contract GameVarAndFee is INTAllContracts {

  constructor(address _contractManager, address _dsAuth, address _dsNote) public {
    contractManager = INTContractManager(_contractManager);
    dsAuth = DSAuthINT(contractManager.getContract("DSAuth"));
    dsnote = DSNoteINT(contractManager.getContract("DSNote"));

  }

}
