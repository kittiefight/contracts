pragma solidity ^0.5.5;

import "../proxy/Proxied.sol";
import "../../interfaces/ERC721.sol";

contract KittieHellDungeon is Proxied {
    ERC721 public cryptoKitties;

    constructor(ERC721 _cryptoKitties) public {
        setCryptoKitties(_cryptoKitties);
    }

    function setCryptoKitties(ERC721 _cryptoKitties) public onlyOwner {
        cryptoKitties = _cryptoKitties;
    }

    function transfer(address _to, uint256 _kittyID)
        external onlyContract(CONTRACT_NAME_KITTIEHELL)
    {
        cryptoKitties.transfer(_to, _kittyID);
    }

    function transferFrom(address _owner, uint256 _kittyID)
        external only2Contracts(CONTRACT_NAME_KITTIEHELL, CONTRACT_NAME_KITTIEHELL_DB)
    {
        cryptoKitties.transferFrom(_owner, address(this), _kittyID);
    }
}