pragma solidity ^0.5.5;


/// @title CryptoKittiesCore mock
/// @author Panos
/// @dev The main CryptoKittiesCore contract mock for testing purposes.
contract KittyCore {

    mapping(uint256 => address) private kitties;

    constructor() public {
        kitties[0] = msg.sender;
    }

    function ownerOf(uint256 _tokenId) external view returns (address owner) {
        return kitties[_tokenId];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        require(kitties[_tokenId] == _from);
        kitties[_tokenId] = _to;
    }
}
