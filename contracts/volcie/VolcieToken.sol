pragma solidity ^0.5.5;

import "../libs/openzeppelin_v2_5_0/token/ERC721/ERC721.sol";
import "../libs/openzeppelin_v2_5_0/token/ERC721/ERC721Enumerable.sol";
import "../libs/openzeppelin_v2_5_0/token/ERC721/ERC721Pausable.sol";
import "../libs/openzeppelin_v2_5_0/access/roles/MinterRole.sol";
import "../libs/openzeppelin_v2_5_0/math/SafeMath.sol";
import "../libs/openzeppelin_v2_5_0/drafts/Counters.sol";
import "../libs/StringUtils.sol";
import "./VolcieTokenMetadata.sol";

contract VolcieToken is ERC721, ERC721Enumerable, ERC721Pausable, VolcieTokenMetadata, MinterRole {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using StringUtils for string;
    using StringUtils for uint256;

    string constant NAME     = "Kittiefight VOLCIE";
    string constant SYMBOL   = "VOLCIE";
    string constant BASE_URI = "https://volcie.kittiefight.io/metadata/";

    struct TokenProperties {
        uint256 lpAddress;
        uint256 lpAmount;
        uint256 creationTime;
    }

    Counters.Counter nextTokenId;       // Provides unique identifier for Ethie token. 0 value is invalid

    mapping (uint256 => TokenProperties) public properties;

    constructor() VolcieTokenMetadata(NAME, SYMBOL) public {
        _setBaseURI(BASE_URI);
        nextTokenId.increment();    // First token should have tokenId = 1;
    }

    /**
     * @notice Mint a new Ethie token
     * @param to Owner of a new token
     * @param lpToken Token locked as collaterla for this Volcie
     * @param lockPeriod Lock time
     * @return id of the new token
     */
    function mint(address to, address lpToken, uint256 lpAmount)  public onlyMinter returns (uint256) {
        uint256 tokenId = nextTokenId.current();
        nextTokenId.increment();
        properties[tokenId] = TokenProperties({
            lpToken: lpToken,
            lpAmount: lpAmount,
            creationTime: now
        });
        _mint(to, tokenId);
        return tokenId;
    }

    function burn(uint256 tokenId) public onlyMinter {
        _burn(tokenId);
    }

    function setBaseURI(string calldata baseURI) external onlyMinter {
        _setBaseURI(baseURI);
    }

    function name(uint256 tokenId) public view returns(string memory) {
        TokenProperties memory p = properties[tokenId];
        require(p.ethAmount > 0, "VolcieToken: name query for nonexistent token");
        return generateName(tokenId, p.lpAddress, p.lpAmount, p.creationTime);
    }

    function allTokenOf(address holder) public view returns(uint256[] memory) {
        uint256 balance = balanceOf(holder);
        uint256[] memory tokens = new uint256[](balance);
        for(uint256 i = 0; i < balance; i++){
            uint256 idx = tokenOfOwnerByIndex(holder, i);
            tokens[i] = idx;
        }
        return tokens;
    }


    function generateName(uint256 tokenId, address lpAddress, uint256 lpAmount, uint256 creationTime) public pure returns(string memory) {
        string memory id  = tokenId.fromUint256();
        string memory amnt = lpAmount.fromUint256(18, 4);
        string memory creation = creationTime.fromUint256();
        return StringUtils.concat(amnt,"KTY-LP").concat("_CR").concat(creation).concat("_").concat(id);
    }

}
