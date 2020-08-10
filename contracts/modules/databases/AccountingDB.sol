pragma solidity ^0.5.5;

import "../proxy/Proxied.sol";
import "./GenericDB.sol";
import "../../libs/SafeMath.sol";

contract AccountingDB is Proxied {
    using SafeMath for uint256;

    GenericDB public genericDB;

    constructor(GenericDB _genericDB) public {
        setGenericDB(_genericDB);
    }

    function setGenericDB(GenericDB _genericDB) public onlyOwner {
        genericDB = _genericDB;
    }

    /**
    * @dev record actual kittie listing fee in ether and in uniswap swapped kty for each kittie listed
    */
    function recordKittieListingFee(uint256 kittieId, uint256 listingFeeEther, uint256 listingFeeKty)
        external
        onlyContract(CONTRACT_NAME_GAMECREATION)
    {
        genericDB.setUintStorage(
            CONTRACT_NAME_ACCOUNTING_DB,
            keccak256(abi.encodePacked(kittieId, "kittieListingFeeEther")),
            listingFeeEther);

        genericDB.setUintStorage(
            CONTRACT_NAME_ACCOUNTING_DB,
            keccak256(abi.encodePacked(kittieId, "kittieListingFeeKty")),
            listingFeeKty);
    }

    /**
     * @dev set total spent "ether" and total uniswap auto-swapped KTY for each game
    */
    function setTotalSpentInGame(uint256 gameId, uint256 etherAmount, uint256 ktyAmount)
        external
        only3Contracts(CONTRACT_NAME_GAMECREATION, CONTRACT_NAME_GAMEMANAGER, CONTRACT_NAME_KITTIEHELL)
    {
        _setTotalSpentInGame(gameId, etherAmount, ktyAmount);
    }

    function setListingFeeInGame(uint256 _gameId, uint256 _kittyRed, uint256 _kittyBlack)
        external
        onlyContract(CONTRACT_NAME_GAMECREATION)
    {
        (uint256 _listingFeeEthRed, uint256 _listingFeeKtyRed) = getKittieListingFee(_kittyRed);
        _setTotalSpentInGame(_gameId, _listingFeeEthRed, _listingFeeKtyRed);
        
        (uint256 _listingFeeEthBlack, uint256 _listingFeeKtyBlack) = getKittieListingFee(_kittyBlack);
        _setTotalSpentInGame(_gameId, _listingFeeEthBlack, _listingFeeKtyBlack);
    }

    // getters
     ///@dev return listing fee in ether and swapped listing fee KTY for each kittie with kittieId listed
    function getKittieListingFee(uint256 kittieId)
    public view returns (uint256, uint256)
    {
        uint256 _listingFeeEther = genericDB.getUintStorage(
            CONTRACT_NAME_ACCOUNTING_DB,
            keccak256(abi.encodePacked(kittieId, "kittieListingFeeEther")));
        uint256 _listingFeeKty = genericDB.getUintStorage(
            CONTRACT_NAME_ACCOUNTING_DB,
            keccak256(abi.encodePacked(kittieId, "kittieListingFeeKty")));
        return (_listingFeeEther, _listingFeeKty);
    }

    // internal functions
     /**
     * @dev set total spent "ether" and total uniswap auto-swapped KTY for each game
    */
    function _setTotalSpentInGame(uint256 _gameId, uint256 _etherAmount, uint256 _ktyAmount)
        internal
    {
        uint256 prevEtherAmount = genericDB.getUintStorage(
            CONTRACT_NAME_ACCOUNTING_DB,
            keccak256(abi.encodePacked(_gameId, "totalSpentInGame")));
        genericDB.setUintStorage(
            CONTRACT_NAME_ACCOUNTING_DB,
            keccak256(abi.encodePacked(_gameId, "totalSpentInGame")),
            prevEtherAmount.add(_etherAmount));

        uint256 prevKtyAmount = genericDB.getUintStorage(
            CONTRACT_NAME_ACCOUNTING_DB,
            keccak256(abi.encodePacked(_gameId, "totalSwappedKtyInGame")));
        genericDB.setUintStorage(
            CONTRACT_NAME_ACCOUNTING_DB,
            keccak256(abi.encodePacked(_gameId, "totalSwappedKtyInGame")),
            prevKtyAmount.add(_ktyAmount));
    }
    
}