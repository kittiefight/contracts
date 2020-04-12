pragma solidity ^0.5.5;

import "../libs/openzeppelin_v2_5_0/token/ERC721/ERC721Full.sol";
import "../libs/openzeppelin_v2_5_0/token/ERC721/ERC721Pausable.sol";
import "../libs/openzeppelin_v2_5_0/access/roles/MinterRole.sol";
import "../libs/openzeppelin_v2_5_0/math/SafeMath.sol";
import "../libs/openzeppelin_v2_5_0/drafts/Counters.sol";
import "../libs/StringUtils.sol";

contract EthieToken is ERC721Full, ERC721Pausable, MinterRole {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using StringUtils for string;
    using StringUtils for uint256;

    string constant NAME    = 'Kittiefight Ethie';
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

    /**
     * @notice Mint a new Ethie token
     * @param to Owner of a new token
     * @param ethAmount Ether value of the new token
     * @param lockTime Lock time
     * @return id of the new token
     */
    function mint(address to, uint256 ethAmount, uint256 lockTime) public onlyMinter returns (uint256) {
        uint256 tokenId = nextTokenId.current();
        nextTokenId.increment();
        properties[tokenId] = TokenProperties({
            ethAmount: ethAmount,
            generation: generation.current(),
            lockTime: lockTime
        });
        _mint(to, tokenId);
        return tokenId;
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "EthieToken: caller is not owner nor approved");
        //TODO return ETH
        _burn(tokenId);
    }

    function incrementGeneration() public onlyMinter {
        generation.increment();
    }

    function name(uint256 tokenId) public view returns(string memory) {
        TokenProperties memory p = properties[tokenId];
        require(p.ethAmount > 0, "EthieToken: name query for nonexistent token");
        string memory eth = p.ethAmount.fromUint256(18, 4);
        string memory gen = p.generation.fromUint256();
        string memory lock = p.lockTime.fromUint256();
        return StringUtils.concat(eth,"ETH").concat("_G").concat(gen).concat("_LOCK").concat(lock).concat("_").concat(tokenId.fromUint256());
    }
}
