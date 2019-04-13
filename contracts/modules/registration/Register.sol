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

import "../databases/ProfileDB.sol";
import "../proxy/Proxied.sol";

/**
 * @title Register
 * @author @psychoplasma
 */
contract Register is Proxied {
  ProfileDB public profileDB;

  constructor() {
    profileDB = ProfileDB(getContract(CONTRACT_NAME_PROFILE_DB));
  }

  function register(address account) external onlyProxy returns (bool) {}
  function update(address account) external onlyProxy {} 
  function login(address account) external onlyProxy returns (bool) {}
  function generateReferalHash(address account) external onlyProxy returns (bytes32 _hash) {}
  function updateKitty(address account, kitty) external onlyProxy returns (bool) {}
  function sendCoinsTo(uint256 amount, address to) external onlyProxy returns (bool) {}
  function exchangeCoinsForEth(uint256 amount, address to) external onlyProxy returns (bool) {}
  function stakeSuperDAO(uint256 amount, address) external onlyProxy returns (bool) {}
  function payFees(uint256 amount) external onlyProxy returns (bool) {}
  function holdCoins(uint256 amount) external onlyProxy returns (bool) {}
  function releaseCoins(uint256 amount) external onlyProxy returns (bool) {}

  function checkRegistered() public view returns (bool) {}
  function getAddressAssets() public view returns (address) {}
  function isRegistered(address account) public view returns (bool) {}
  function hasKitties(address account) public view returns (bool) {}
  function iterateKitties(address account) public view returns (kitties) {}

  function registerRole() internal {}
  function createProfile() internal {}
}
