/**
 * @title kittiehellDB
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
pragma solidity >=0.5.0 <0.6.0;

import "./interfaces/INTAllContracts.sol";
import "./interfaces/INTContractManager.sol";

contract kittiehellDB is INTAllContracts {


INTContractManager contractManager;
DSAuthINT dsAuth;
DSNoteINT dsnote;
TimeContractINT xxx;
KittieHellINT xxx;

  constructor(address _contractManager, address _dsAuth, address _dsNote) public {
    contractManager = INTContractManager(_contractManager);

    dsAuth = DSAuthINT(contractManager.getContract("DSAuth"));
    dsnote = DSNoteINT(contractManager.getContract("DSNote"));

  }

  //set up all other initial contracts
  function initContracts() public auth returns(bool){
    // yy = xxx(contractManager.getContract("zzz"));
    // yy = xxx(contractManager.getContract("zzz"));
    // yy = xxx(contractManager.getContract("zzz"));
    // yy = xxx(contractManager.getContract("zzz"));
    // yy = xxx(contractManager.getContract("zzz"));

  }


}
