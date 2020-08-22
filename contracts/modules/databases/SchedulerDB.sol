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
import "./GenericDB.sol";
import "../../libs/SafeMath.sol";

/**
 * @title SchedulerDB
 * @author @pash7ka
 */
contract SchedulerDB is Proxied {
    using SafeMath for uint256;

    GenericDB public genericDB;

    function setGenericDB(GenericDB _genericDB) public onlyOwner {
        genericDB = _genericDB;
    }

    function getHeadGame() internal view returns (uint256) {
        return
            genericDB.getUintStorage(
                CONTRACT_NAME_SCHEDULER,
                keccak256(abi.encodePacked("headGame"))
            );
    }

    function setHeadGame(uint256 headGame) internal {
        return
            genericDB.setUintStorage(
                CONTRACT_NAME_SCHEDULER,
                keccak256(abi.encodePacked("headGame")),
                headGame
            );
    }

    function getTailGame() internal view returns (uint256) {
        return
            genericDB.getUintStorage(
                CONTRACT_NAME_SCHEDULER,
                keccak256(abi.encodePacked("tailGame"))
            );
    }

    function setTailGame(uint256 tailGame) internal {
        return
            genericDB.setUintStorage(
                CONTRACT_NAME_SCHEDULER,
                keccak256(abi.encodePacked("tailGame")),
                tailGame
            );
    }

    function getNoOfGames() internal view returns (uint256) {
        return
            genericDB.getUintStorage(
                CONTRACT_NAME_SCHEDULER,
                keccak256(abi.encodePacked("noOfGames"))
            );
    }

    function setNoOfGames(uint256 noOfGames) internal {
        return
            genericDB.setUintStorage(
                CONTRACT_NAME_SCHEDULER,
                keccak256(abi.encodePacked("noOfGames")),
                noOfGames
            );
    }

    function getGame(uint256 gameId) internal view returns (bytes memory) {
        return
            genericDB.getBytesStorage(
                CONTRACT_NAME_SCHEDULER,
                keccak256(abi.encodePacked(gameId, "gameList"))
            );
    }

    function setGame(uint256 gameId, bytes memory encodedGame) internal {
        genericDB.setBytesStorage(
            CONTRACT_NAME_SCHEDULER,
            keccak256(abi.encodePacked(gameId, "gameList")),
            encodedGame
        );
    }

    function getKittyOwner(uint256 kittyId) internal view returns (address) {
        return
            genericDB.getAddressStorage(
                CONTRACT_NAME_SCHEDULER,
                keccak256(abi.encodePacked(kittyId, "kittyOwner"))
            );
    }

    function setKittyOwner(uint256 kittyId, address owner) internal {
        genericDB.setAddressStorage(
            CONTRACT_NAME_SCHEDULER,
            keccak256(abi.encodePacked(kittyId, "kittyOwner")),
            owner
        );
    }

    function getKittyListed(uint256 kittyId) public view returns (bool) {
        return
            genericDB.getBoolStorage(
                CONTRACT_NAME_SCHEDULER,
                keccak256(abi.encodePacked(kittyId, "isKittyListed"))
            );
    }

    function setKittyListed(uint256 kittyId, bool isListed) internal {
        genericDB.setBoolStorage(
            CONTRACT_NAME_SCHEDULER,
            keccak256(abi.encodePacked(kittyId, "isKittyListed")),
            isListed
        );
    }

    function getNoOfKittiesListed() public view returns (uint256) {
        return
            genericDB.getUintStorage(
                CONTRACT_NAME_SCHEDULER,
                keccak256(abi.encodePacked("noOfKittiesListed"))
            );
    }

    function setNoOfKittiesListed(uint256 noOfKittiesListed) internal {
        return
            genericDB.setUintStorage(
                CONTRACT_NAME_SCHEDULER,
                keccak256(abi.encodePacked("noOfKittiesListed")),
                noOfKittiesListed
            );
    }

    function getKittyId(uint256 idx) internal view returns (uint256) {
        return
            genericDB.getUintStorage(
                CONTRACT_NAME_SCHEDULER,
                keccak256(abi.encodePacked(idx, "kittyList"))
            );
    }

    function setKittyId(uint256 idx, uint256 kittyId) internal {
        genericDB.setUintStorage(
            CONTRACT_NAME_SCHEDULER,
            keccak256(abi.encodePacked(idx, "kittyList")),
            kittyId
        );
    }

    function getImmediateStart() internal view returns (bool) {
        return
            genericDB.getBoolStorage(
                CONTRACT_NAME_SCHEDULER,
                keccak256(abi.encodePacked("immediateStart"))
            );
    }

    function setImmediateStart(bool immediateStart) internal {
        genericDB.setBoolStorage(
            CONTRACT_NAME_SCHEDULER,
            keccak256(abi.encodePacked("immediateStart")),
            immediateStart
        );
    }
}
