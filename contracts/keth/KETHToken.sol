pragma solidity ^0.5.5;

import "../libs/openzeppelin_v2_5_0/token/ERC721/ERC721Full.sol";
import "../libs/openzeppelin_v2_5_0/token/ERC721/ERC721Pausable.sol";
import "../libs/openzeppelin_v2_5_0/access/roles/MinterRole.sol";
import "../libs/openzeppelin_v2_5_0/math/SafeMath.sol";
import "../libs/openzeppelin_v2_5_0/drafts/Counters.sol";

contract KETHToken is ERC721Full, ERC721Pausable, MinterRole {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

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
}
