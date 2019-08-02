pragma solidity ^0.5.5;

import "../interfaces/ERC721.sol";
import "../interfaces/ERC20Advanced.sol";
import "../libs/SafeMath.sol";
import "../authority/Owned.sol";


contract MockERC721Token is ERC721, Owned {
  using SafeMath for uint256;

  // Mapping from token ID to owner
  mapping (uint256 => address) private _tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) private _tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) private _ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) private _operatorApprovals;

  function mint(address to, uint256 tokenId) public onlyOwner {
    _mint(to, tokenId);
  }

  function totalSupply() public view returns (uint256) {
    return 0;
  }

  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0));
    return _ownedTokensCount[owner];
  }

  function ownerOf(uint256 tokenId) public view returns (address) {
    address owner = _tokenOwner[tokenId];
    require(owner != address(0));
    return owner;
  }

  function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
    return false;
  }

  function approve(address to, uint256 tokenId) public {
    address owner = ownerOf(tokenId);
    require(to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  function getApproved(uint256 tokenId) public view returns (address) {
    require(_exists(tokenId));
    return _tokenApprovals[tokenId];
  }

  function isApprovedForAll(address owner, address operator) public view returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  function transfer(address to, uint256 tokenId) external {
    require(_isApprovedOrOwner(msg.sender, tokenId));

    _transferFrom(msg.sender, to, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) external {
    require(_isApprovedOrOwner(msg.sender, tokenId));
    _transferFrom(from, to, tokenId);
  }

  function _exists(uint256 tokenId) internal view returns (bool) {
    address owner = _tokenOwner[tokenId];
    return owner != address(0);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  function _mint(address to, uint256 tokenId) internal {
    require(to != address(0));
    require(!_exists(tokenId));

    _tokenOwner[tokenId] = to;
    _ownedTokensCount[to] = _ownedTokensCount[to].add(1);

    emit Transfer(address(0), to, tokenId);
  }

  function _burn(address owner, uint256 tokenId) internal {
    require(ownerOf(tokenId) == owner);

    _clearApproval(tokenId);

    _ownedTokensCount[owner]= _ownedTokensCount[owner].sub(1);
    _tokenOwner[tokenId] = address(0);

    emit Transfer(owner, address(0), tokenId);
  }

  function _burn(uint256 tokenId) internal {
    _burn(ownerOf(tokenId), tokenId);
  }

  function _transferFrom(address from, address to, uint256 tokenId) internal {
    require(ownerOf(tokenId) == from);
    require(to != address(0));

    _clearApproval(tokenId);

    _ownedTokensCount[from]= _ownedTokensCount[from].sub(1);
    _ownedTokensCount[to] = _ownedTokensCount[to].add(1);

    _tokenOwner[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  function _clearApproval(uint256 tokenId) private {
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
  }

  function getKitty(uint256 _id)
        external
        view
        returns (uint256)
    {
        if(_id == 1001) return 512955438081049600613224346938352058409509756310147795204209859701881294;
        if(_id == 1555108) return 24171491821178068054575826800486891805334952029503890331493652557302916;
        if(_id == 1267904) return 290372710203698797209297887795752417072070342201768110150904359522134138;
        if(_id == 454545) return 513122167084233935341778471073524505661220812329150746642689453393853933;
        if(_id == 333) return 456127237212346560521864475286743916398626059323515127575007554868490605;
        return 1139226730704705906933029377164498815783772207947233414549835875685085217;

    }
}