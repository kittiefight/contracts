pragma solidity ^0.5.5;

import "../libs/openzeppelin_v2_5_0/token/ERC721/ERC721Full.sol";
import "../libs/openzeppelin_v2_5_0/token/ERC721/ERC721Pausable.sol";
import "../libs/openzeppelin_v2_5_0/access/roles/MinterRole.sol";
import "../libs/openzeppelin_v2_5_0/math/SafeMath.sol";
import "../libs/openzeppelin_v2_5_0/drafts/Counters.sol";
import "../libs/StringUtils.sol";

contract KETHToken is ERC721Full, ERC721Pausable, MinterRole {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using StringUtils for string;
    using StringUtils for uint256;

    string constant NAME    = 'Kittiefight ETH';
    string constant SYMBOL  = 'KETH';

    struct TokenProperties {
        uint256 ethAmount;
        uint256 generation;
        uint256 lockTime;
    }

    Counters.Counter nextTokenId;       // Provides unique identifier for KETH token. 0 value is invalid
    Counters.Counter generation; // Stores current genereation of KETH tokens

    mapping (uint256 => TokenProperties) public properties;

    constructor() ERC721Full(NAME, SYMBOL) public {
        nextTokenId.increment();    // First token should have tokenId = 1;
    }

    function mint(address to, uint256 ethAmount, uint256 lockTime) public onlyMinter returns (bool) {
        uint256 tokenId = nextTokenId.current();
        nextTokenId.increment();
        properties[tokenId] = TokenProperties({
            ethAmount: ethAmount,
            generation: generation.current(),
            lockTime: lockTime
        });
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "KETHToken: caller is not owner nor approved");
        //TODO return ETH
        _burn(tokenId);
    }

    function incrementGeneration() public onlyMinter {
        generation.increment();
    }

    function name(uint256 tokenId) public view returns(string memory) {
        TokenProperties memory p = properties[tokenId];
        require(p.ethAmount > 0, "KETHToken: operator query for nonexistent token");
        string memory gen = p.generation.fromUint256();
        string memory lock = p.lockTime.fromUint256();
        string memory id = tokenId.fromUint256();
        return StringUtils.concat("G", gen).concat("_LOCK").concat(lock).concat("_").concat(id);
    }
}
