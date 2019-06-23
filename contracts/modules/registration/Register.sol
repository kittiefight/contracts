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

import "../../libs/SafeMath.sol";
import "../../authority/SystemRoles.sol";
import "../databases/ProfileDB.sol";
import "../databases/RoleDB.sol";
import "../proxy/Proxied.sol";
import "../../interfaces/ERC721.sol";
import "../../interfaces/ERC20Standard.sol";


/**
 * @title Register
 * @dev Responsible for user profile creation/modification
 * and CryptoKitties registration/removal under existing profiles.
 * This contract keeps the registered CryptoKitties, SuperDAO Tokens
 * and KittieFight Tokens. Therefore before user creating a profile
 * or any kind of interaction with the whole system, required approvals
 * for both CryptoKitties and ERC20 tokens should be given to this contarct in advance.
 * @author @psychoplasma
 */
contract Register is Proxied, SystemRoles {
  using SafeMath for uint256;

  ProfileDB public profileDB;
  RoleDB public roleDB;
  ERC721 public cryptoKitties;
  ERC20Standard public kittieFightToken;
  ERC20Standard public superDaoToken;

  string constant internal KITTIE_STATUS_IDLE = "idle";
  string constant internal KITTIE_STATUS_PLAYING = "playing";
  string constant internal KITTIE_STATUS_DEAD = "dead";
  string constant internal KITTIE_STATUS_GHOST = "ghost";


  /**
   * @dev Sets related database contracts and tokens
   * ProfileDB, RoleDB, CryptoKitties, KittieFightToken, SuperDAOToken
   * @dev Can be called only by the owner of this contract
   */
  function initialize() external onlyOwner {
    profileDB = ProfileDB(proxy.getContract(CONTRACT_NAME_PROFILE_DB));
    roleDB = RoleDB(proxy.getContract(CONTRACT_NAME_ROLE_DB));
    cryptoKitties = ERC721(proxy.getContract('CryptoKitties'));
    kittieFightToken = ERC20Standard(proxy.getContract('KittieFightToken'));
    superDaoToken = ERC20Standard(proxy.getContract('SuperDAOToken'));
  }

  /**
   * @dev Creates a new profile with the given address in ProfileDB
   * and sets its role to `bettor` by default.
   * @dev Can be called only through Proxy contract
   * @param account address Address of the user to be registered
   */
  function register(address account)
    external
    onlyProxy
    returns (bool)
  {
    profileDB.create(account);
    _registerRole(account, BETTOR_ROLE);
  }

  /**
   * @dev Locks the given CryptoKitty to this contract. Prior to this operation,
   * the owner of the given CryptoKitty should approve this contract for trasfer operation.
   * @dev Can be called only through Proxy contract
   * @param account address Address of the owner of CryptoKitty to be locked
   * @param kittieId uint256 Id of CryptoKitty to be locked
   */
  function lockKittie(
    address account,
    uint256 kittieId
  )
    external
    onlyProxy
    returns (bool)
  {
    require(cryptoKitties.ownerOf(kittieId) == account);
    // TODO: Change the owner address to the address of kittie custody contract later
    cryptoKitties.transferFrom(account, address(this), kittieId);
    profileDB.addKittie(account, kittieId, 0, KITTIE_STATUS_IDLE);
    _registerRole(account, PLAYER_ROLE);
    return true;
  }

  /**
   * @dev Transfers the given CryptoKitty from this contract to its user. The kitten's
   * status should not be dead/ghots nor playing. Otherwise the tx will be reverted.
   * @dev Can be called only through Proxy contract
   * @param account address Address of the owner of CryptoKitty to be released
   * @param kittieId uint256 Id of CryptoKitty to be released
   */
  function releaseKittie(
    address account,
    uint256 kittieId
  )
    external
    onlyProxy
    returns (bool)
  {
    // TODO: Change the owner address to the address of kittie custody contract later
    require(cryptoKitties.ownerOf(kittieId) == address(this));
    // TODO: Has to check KittyHellDB whether the Kittie is there or not
    profileDB.removeKittie(account, kittieId);
    // If there is no kittie left in custody, remove player status from the profile
    if (profileDB.getKittieCount(account) == 0) {
      _removeRole(account, PLAYER_ROLE);
    }
    cryptoKitties.transfer(account, kittieId);
    return true;
  }

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
  )
    external
    onlyContract(contractName)
    returns (bool)
  {
    // TODO: Change the owner address to the address of kittie custody contract later
    require(cryptoKitties.ownerOf(kittieId) == address(this));
    profileDB.setKittieAttributes(account, kittieId, deadAt, kittieStatus);
    return true;
  }

  /**
   * @dev ???
   * @dev Can be called only through Proxy contract
   * @param account address
   * @param to address
   * @param amount uint256
   */
  // TODO: Implement this
  function sendTokensTo(address account, address to, uint256 amount)
    external
    onlyProxy
    returns (bool)
  {
    require(kittieFightToken.transferFrom(account, to, amount));
    return true;
  }

  /**
   * @dev ???
   * @dev Can be called only through Proxy contract
   * @param account address
   * @param amount uint256
   */
  // TODO: Implement this
  function exchangeTokensForEth(address payable account, uint256 amount)
    external
    onlyProxy
    returns (bool)
  {
    // TODO: Calculate exchange rate according to what??!
    uint256 exhangeRate = 1;
    require(amount > 0);
    require(kittieFightToken.transferFrom(account, address(this), amount));
    account.transfer(amount.mul(exhangeRate));
    profileDB.setKittieFightTokens(account, amount);
    return true;
  }

  /**
   * @dev Stakes SuperDAO tokens to this contract and saves the stake
   * amount and staking status on ProfileDB.
   * @dev Can be called only through Proxy contract
   * @param account address Address of the user who is staking
   * @param amount uint256 Amount of SuperDAO tokens to be staked
   */
  function stakeSuperDAO(address account, uint256 amount)
    external
    onlyProxy
    returns (bool)
  {
    require(amount > 0);
    // TODO: Change the owner address to the address of token custody contract later
    require(superDaoToken.transferFrom(account, address(this), amount));
    profileDB.setSuperDAOTokens(account, amount, true);
    return true;
  }

  /**
   * @dev ???
   * @dev Can be called only through Proxy contract
   * @param account address
   * @param amount uint256
   */
  // TODO: Implement this
  function payFees(address account, uint256 amount)
    external
    onlyProxy
    returns (bool)
  {
  }

  /**
   * @dev Locks KittieFight tokens to this contract and saves the locked
   * amount on ProfileDB under account's profile.
   * @dev Can be called only through Proxy contract
   * @param account address Address of the user whose tokens will be locked
   * @param amount uint256 Amount of KittieFight tokens to be locked
   */
  function lockTokens(address account, uint256 amount)
    external
    onlyProxy
    returns (bool)
  {
    require(amount > 0);
    uint256 lockedBalance = profileDB.getKittieFightTokens(account);
    // TODO: Change the owner address to the address of token custody contract later
    require(kittieFightToken.transferFrom(account, address(this), amount));
    profileDB.setKittieFightTokens(account, lockedBalance.add(amount));
    return true;
  }

  /**
   * @dev Releases KittieFight tokens from this contract to `account`.
   * Does not allow to release an amount more than the locked amount.
   * Updates the locked amount on ProfileDB accordingly after release.
   * @dev Can be called only through Proxy contract
   * @param account address Address of the user whose tokens will be released
   * @param amount uint256 Amount of KittieFight tokens to be released
   */
  function releaseTokens(address account, uint256 amount)
    external
    onlyProxy
    returns (bool)
  {
    require(amount > 0);
    uint256 lockedBalance = profileDB.getKittieFightTokens(account);
    require(lockedBalance >= amount);
    profileDB.setKittieFightTokens(account, lockedBalance.sub(amount));
    require(kittieFightToken.transfer(account, amount));
    return true;
  }

  // TODO: Implement this
  function getAddressAssets() public view returns (address) {
  }

  /**
   * @dev Checks whether there is a profile on ProfileDB with the given address.
   * @param account address Address to be checked
   * @return bool true if there is a registered profile with the given address, false otherwise.
   */
  function isRegistered(address account) public view returns (bool) {
    return profileDB.doesProfileExist(account);
  }

  /**
   * @dev Checks whether the kittie provided is registered to the system under the given account.
   * @param account address Account to be checked against kittie
   * @param kittieId uint256 Kittie to be checked if it exists
   * @return bool true if the kittie is registered to the system under the given account
   */
  function doesKittieBelong(address account, uint256 kittieId) public view returns (bool) {
    return profileDB.doesKittieExist(account, kittieId);
  }

  /**
   * @dev Checks whether there is a kittie registered to the system under the given account.
   * @param account address Address to be checked
   * @return bool true if there is a kittie registered to the system under the given account
   */
  function hasKitties(address account) public view returns (bool) {
    return profileDB.getKitties(account).length > 0;
  }

  /**
   * @dev Registers a role for the given address on RoleDB.
   * @param account address Address to be registered for the provided role
   * @param role string Role to be assigned to the given address
   */
  function _registerRole(address account, string memory role) internal {
    roleDB.addRole(CONTRACT_NAME_REGISTER, role, account);
  }

  /**
   * @dev Removes a role from the given address on RoleDB.
   * @param account address Address that the provided role will be removed from
   * @param role string Role to be removed from the given address
   */
  function _removeRole(address account, string memory role) internal {
    roleDB.removeRole(CONTRACT_NAME_REGISTER, role, account);
  }
}
