pragma solidity ^0.5.5;

import "../libs/openzeppelin_v2_5_0/token/ERC721/ERC721.sol";
import "../libs/openzeppelin_v2_5_0/token/ERC721/ERC721Enumerable.sol";
import "../libs/openzeppelin_v2_5_0/token/ERC721/ERC721Pausable.sol";
import "../libs/openzeppelin_v2_5_0/access/roles/MinterRole.sol";
import "../libs/openzeppelin_v2_5_0/math/SafeMath.sol";
import "../libs/openzeppelin_v2_5_0/drafts/Counters.sol";
import "../libs/StringUtils.sol";
import "./EthieTokenMetadata.sol";

contract EthieToken is ERC721, ERC721Enumerable, ERC721Pausable, EthieTokenMetadata, MinterRole {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using StringUtils for string;
    using StringUtils for uint256;

    string constant NAME     = "Kittiefight Ethie";
    string constant SYMBOL   = "Ethie";
    string constant BASE_URI = "https://ethie.kittiefight.io/metadata/";

    struct TokenProperties {
        uint256 ethAmount;
        uint256 generation;
        uint256 creationTime;
        uint256 lockPeriod;
    }

    Counters.Counter nextTokenId;       // Provides unique identifier for Ethie token. 0 value is invalid
    Counters.Counter generation; // Stores current genereation of Ethie tokens

    mapping (uint256 => TokenProperties) public properties;

    constructor() EthieTokenMetadata(NAME, SYMBOL) public {
        _setBaseURI(BASE_URI);
        nextTokenId.increment();    // First token should have tokenId = 1;
    }

    /**
     * @notice Mint a new Ethie token
     * @param to Owner of a new token
     * @param ethAmount Ether value of the new token
     * @param lockPeriod Lock time
     * @return id of the new token
     */
    function mint(address to, uint256 ethAmount, uint256 lockPeriod) public onlyMinter returns (uint256) {
        uint256 tokenId = nextTokenId.current();
        nextTokenId.increment();
        properties[tokenId] = TokenProperties({
            ethAmount: ethAmount,
            generation: generation.current(),
            creationTime: now,
            lockPeriod: lockPeriod
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

    function setBaseURI(string calldata baseURI) external onlyMinter {
        _setBaseURI(baseURI);
    }

    function name(uint256 tokenId) public view returns(string memory) {
        TokenProperties memory p = properties[tokenId];
        require(p.ethAmount > 0, "EthieToken: name query for nonexistent token");
        return generateName(tokenId, p.ethAmount, p.generation, p.lockPeriod);
    }

    function allTokenOf(address holder) public view returns(uint256[] memory, uint256) {
        uint256 ethBalance = 0;
        uint256 balance = balanceOf(holder);
        uint256[] memory tokens = new uint256[](balance);
        for(uint256 i = 0; i < balance; i++){
            uint256 idx = tokenOfOwnerByIndex(holder, i);
            tokens[i] = idx;
            ethBalance += properties[idx].ethAmount;
        }
        return (tokens, ethBalance);
    }


    function generateName(uint256 tokenId, uint256 ethAmount, uint256 tokenGeneration, uint256 lockPeriod) public pure returns(string memory) {
        string memory id  = tokenId.fromUint256();
        string memory eth = ethAmount.fromUint256(18, 4);
        string memory gen = tokenGeneration.fromUint256();
        string memory lock = lockPeriod.fromUint256();
        return StringUtils.concat(eth,"ETH").concat("_G").concat(gen).concat("_LOCK").concat(lock).concat("_").concat(id);
    }

}
