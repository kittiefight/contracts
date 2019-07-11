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
 * @title IRegister
 * @dev Interface to access to Register contract from corresponding proxy contract.
 * @author @psychoplasma
 */
contract IRegister {

  /**
   * @dev Sets related database contracts and tokens
   * ProfileDB, RoleDB, CryptoKitties, KittieFightToken, SuperDAOToken
   * @dev Can be called only by the owner of this contract
   */
  function initialize() external;

  /**
   * @dev Creates a new profile with the given address in ProfileDB
   * and sets its role to `bettor` by default.
   * @dev Can be called only through Proxy contract
   * @param account address Address of the user to be registered
   */
  function register(address account) external returns (bool);

  /**
   * @dev Locks the given CryptoKitty to this contract. Prior to this operation,
   * the owner of the given CryptoKitty should approve this contract for trasfer operation.
   * @dev Can be called only through Proxy contract
   * @param account address Address of the owner of CryptoKitty to be locked
   * @param kittieId uint256 Id of CryptoKitty to be locked
   */
  function lockKittie(address account, uint256 kittieId) external returns (bool);

  /**
   * @dev Transfers the given CryptoKitty from this contract to its user. The kitten's
   * status should not be dead/ghots nor playing. Otherwise the tx will be reverted.
   * @dev Can be called only through Proxy contract
   * @param account address Address of the owner of CryptoKitty to be released
   * @param kittieId uint256 Id of CryptoKitty to be released
   */
  function releaseKittie(address account, uint256 kittieId) external returns (bool);

  /**
   * @dev Updates the status of the given kitten.
   * @dev Can be called through other system contracts
   * @param contractName string Address of the owner of CryptoKitty to be updated
   * @param account address Address of the owner of CryptoKitty to be updated
   * @param kittieId uint256 Id of CryptoKitty to be updated
   * @param deadAt uint256 Time of death of the kitten if its status dead
   * @param kittieStatus string Status of the kitten in KittieFight system
   */
  function updateKittie(
    string calldata contractName,
    address account,
    uint256 kittieId,
    uint256 deadAt,
    string calldata kittieStatus
  ) external returns (bool);

  /**
   * @dev ???
   * @dev Can be called only through Proxy contract
   * @param account address
   * @param to address
   * @param amount uint256
   */
  function sendTokensTo(address account, address to, uint256 amount) external returns (bool);

  /**
   * @dev ???
   * @dev Can be called only through Proxy contract
   * @param account address
   * @param amount uint256
   */
  function exchangeTokensForEth(address payable account, uint256 amount) external returns (bool);

  /**
   * @dev Stakes SuperDAO tokens to this contract and saves the stake
   * amount and staking status on ProfileDB.
   * @dev Can be called only through Proxy contract
   * @param account address Address of the user who is staking
   * @param amount uint256 Amount of SuperDAO tokens to be staked
   */
  function stakeSuperDAO(address account, uint256 amount) external returns (bool);

  /**
   * @dev ???
   * @dev Can be called only through Proxy contract
   * @param account address
   * @param amount uint256
   */
  function payFees(address account, uint256 amount) external returns (bool);

  /**
   * @dev Locks KittieFight tokens to this contract and saves the locked
   * amount on ProfileDB under account's profile.
   * @dev Can be called only through Proxy contract
   * @param account address Address of the user whose tokens will be locked
   * @param amount uint256 Amount of KittieFight tokens to be locked
   */
  function lockTokens(address account, uint256 amount) external returns (bool);

  /**
   * @dev Releases KittieFight tokens from this contract to `account`.
   * Does not allow to release an amount more than the locked amount.
   * Updates the locked amount on ProfileDB accordingly after release.
   * @dev Can be called only through Proxy contract
   * @param account address Address of the user whose tokens will be released
   * @param amount uint256 Amount of KittieFight tokens to be released
   */
  function releaseTokens(address account, uint256 amount) external returns (bool);

  function getAddressAssets() public view returns (address);

  /**
   * @dev Checks whether there is a profile on ProfileDB with the given address.
   * @param account address Address to be checked
   * @return bool true if there is a registered profile with the given address, false otherwise.
   */
  function isRegistered(address account) public view returns (bool);

  /**
   * @dev Checks whether there is a kittie registered to the system under the given account.
   * @param account address Address to be checked
   * @return bool true if there is a kittie registered to the system under the given account
   */
  function hasKitties(address account) public view returns (bool);
}
