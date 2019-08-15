pragma solidity ^0.5.5;

import "./GenericDB.sol";
import "../proxy/Proxied.sol";
import "../../libs/SafeMath.sol";
import "../endowment/EndowmentFund.sol";

contract EndowmentDB is Proxied {
  using SafeMath for uint256;

  GenericDB public genericDB;

  // TABLE_KEY_PROFILE for ProfileDB lookup (read-only).
  bytes32 internal constant TABLE_KEY_PROFILE = keccak256(abi.encodePacked("ProfileTable"));
  // TABLE_KEY_HONEYPOT defines a set for active Honeypots of EndowmentFund.
  bytes32 internal constant TABLE_KEY_HONEYPOT = keccak256(abi.encodePacked("HoneypotTable"));
  // TABLE_KEY_HONEYPOT_DISSOLVED defines a set for dissolved honeypots of EndowmentFund.
  bytes32 internal constant TABLE_KEY_HONEYPOT_DISSOLVED = keccak256(abi.encodePacked("HoneypotDissolvedTable"));
  // TABLE_NAME_CONTRIBUTION_KTY defines a set of KTY contributors of a honeypot of EndowmentFund.
  bytes32 internal constant TABLE_NAME_CONTRIBUTION_KTY = "ContributionTableKTY";
  // TABLE_NAME_CONTRIBUTION_ETH defines a set of ETH contributors of a honeypot of EndowmentFund.
  bytes32 internal constant TABLE_NAME_CONTRIBUTION_ETH = "ContributionTableETH";
  // VAR_KEY_ACTUAL_FUNDS_KTY
  bytes32 internal constant VAR_KEY_ACTUAL_FUNDS_KTY = keccak256(abi.encodePacked("actualFundsKTY"));
  // VAR_KEY_ACTUAL_FUNDS_ETH
  bytes32 internal constant VAR_KEY_ACTUAL_FUNDS_ETH = keccak256(abi.encodePacked("actualFundsETH"));
  // VAR_KEY_INGAME_FUNDS_KTY
  bytes32 internal constant VAR_KEY_INGAME_FUNDS_KTY = keccak256(abi.encodePacked("ingameFundsKTY"));
  // VAR_KEY_INGAME_FUNDS_ETH
  bytes32 internal constant VAR_KEY_INGAME_FUNDS_ETH = keccak256(abi.encodePacked("ingameFundsETH"));

  string internal constant ERROR_DOES_NOT_EXIST = "Not exists";
  string internal constant ERROR_NOT_REGISTERED = "Not registered";
  string internal constant ERROR_ALREADY_EXIST = "Already exists";
  string internal constant ERROR_INSUFFICIENT_FUNDS = "Insufficient funds";

  constructor(GenericDB _genericDB) public {
    setGenericDB(_genericDB);
  }

  function setGenericDB(GenericDB _genericDB) public onlyOwner {
    genericDB = _genericDB;
  }

  function getHoneyPotBalance(uint256 _gameId) public view
  returns (uint256 honeyPotBalanceKTY, uint256 honeyPotBalanceETH)  {
    honeyPotBalanceKTY = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(_gameId, "ktyTotal")));
    honeyPotBalanceETH = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(_gameId, "ethTotal")));

  }

  function updateHoneyPotFund(
    uint256 _gameId, uint256 _kty_amount, uint256 _eth_amount, bool deductFunds
  )
    external
    onlyContract(CONTRACT_NAME_ENDOWMENT_FUND)
    returns (bool)
  {
    uint honeyPotKtyTotal;
    uint honeyPotEthTotal;

    if (_kty_amount > 0){

      // get total Kty availabe in the HoneyPot
      bytes32 honeyPotKtyTotalKey = keccak256(abi.encodePacked(_gameId, "ktyTotal"));
      honeyPotKtyTotal = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, honeyPotKtyTotalKey);

      if (deductFunds){

        require(honeyPotKtyTotal >= _kty_amount,
          "Error: updateHoneyPotFund() insufficient KTY in HoneyPot");

        genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, honeyPotKtyTotalKey, honeyPotKtyTotal.sub(_kty_amount));

      }else{ // add

        genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, honeyPotKtyTotalKey, honeyPotKtyTotal.add(_kty_amount));

      }
    }

    if (_eth_amount > 0){
      // get total Eth availabe in the HoneyPot
      bytes32 honeyPotEthTotalKey = keccak256(abi.encodePacked(_gameId, "ethTotal"));
      honeyPotEthTotal = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, honeyPotEthTotalKey);

      if (deductFunds){

        require(honeyPotEthTotal >= _eth_amount,
          "Error: updateHoneyPotFund() insufficient ETH in HoneyPot");

        genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, honeyPotEthTotalKey, honeyPotEthTotal.sub(_eth_amount));

      }else{ // add

        genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, honeyPotEthTotalKey, honeyPotEthTotal.add(_eth_amount));

      }
    }

    if(honeyPotEthTotal == 0 && honeyPotKtyTotal == 0)
      EndowmentFund(proxy.getContract(CONTRACT_NAME_ENDOWMENT_FUND)).deleteCronJob(_gameId);

    return true;
  }

  function updateEndowmentFund(
    uint256 _kty_amount, uint256 _eth_amount, bool deductFunds
  )
    external
    onlyContract(CONTRACT_NAME_ENDOWMENT_FUND)
    returns (bool)
  {

    if (_kty_amount > 0){

      uint actualFundsKTY = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, VAR_KEY_ACTUAL_FUNDS_KTY);
      if (deductFunds){

        require(actualFundsKTY >= _kty_amount,
          'INSUFFICIENT KTY in Endowment. 1564656805056');

        genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, VAR_KEY_ACTUAL_FUNDS_KTY, actualFundsKTY.sub(_kty_amount));

      }else{ // add
        genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, VAR_KEY_ACTUAL_FUNDS_KTY, actualFundsKTY.add(_kty_amount));

      }
    }

    if (_eth_amount > 0){
      uint actualFundsETH = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, VAR_KEY_ACTUAL_FUNDS_ETH);

      if (deductFunds){

        require(actualFundsETH >= _eth_amount,
          'INSUFFICIENT ETH in Endowment. 1564656589937');

        genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, VAR_KEY_ACTUAL_FUNDS_ETH, actualFundsETH.sub(_eth_amount));

      }else{ // add

        genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, VAR_KEY_ACTUAL_FUNDS_ETH, actualFundsETH.add(_eth_amount));

      }
    }

    return true;
  }

  function getEndowmentBalance() public view
  returns (uint256 endowmentBalanceKTY, uint256 endowmentBalanceETH)  {
    endowmentBalanceKTY = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, VAR_KEY_ACTUAL_FUNDS_KTY);
    endowmentBalanceETH = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, VAR_KEY_ACTUAL_FUNDS_ETH);
  }

  function createHoneypot(
    uint gameId,
    uint state,
    uint createdTime,
    uint ktyTotal,
    uint ethTotal
  )
    external
    onlyContract(CONTRACT_NAME_ENDOWMENT_FUND)
  {
    require(genericDB.pushNodeToLinkedList(CONTRACT_NAME_ENDOWMENT_DB, TABLE_KEY_HONEYPOT, gameId), ERROR_ALREADY_EXIST);
    genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(gameId, "state")), state);
    genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(gameId, "createdTime")), createdTime);
    genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(gameId, "ktyTotal")), ktyTotal);
    genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(gameId, "ethTotal")), ethTotal);
  }

  function getHoneypotState(
    uint gameId
  )
    external
    view returns (uint state, uint256 claimTime)
  {
    return(
      genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(gameId, "state"))),
      genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(gameId, "claimTime")))
    );
  }

  function setHoneypotState( uint _gameId, uint state, uint256 claimTime) external {
    genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(_gameId, "state")), state);
    if (claimTime > 0){
      genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(_gameId, "claimTime")), claimTime);
    }
    else{
      genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(_gameId, "claimTime")), 0);
    }
  }


  function getHoneypotTotal(uint _gameId) external view returns (uint256 totalEth, uint256 totalKty) {
      totalEth = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(_gameId, "ethTotal")));
      totalKty = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(_gameId, "ktyTotal")));
  }

  function dissolveHoneypot(
    uint gameId,
    uint state
  )
    external
    onlyContract(CONTRACT_NAME_ENDOWMENT_FUND)
    /*onlyExistingHoneypot(gameId)*/
  {

    // require(genericDB.pushNodeToLinkedList(CONTRACT_NAME_ENDOWMENT_DB, TABLE_KEY_HONEYPOT_DISSOLVED, gameId));
    // require(genericDB.removeNodeFromLinkedList(CONTRACT_NAME_ENDOWMENT_DB, TABLE_KEY_HONEYPOT, gameId));
    uint256 claimTime = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(gameId, "claimTime")));
    require(claimTime > 0);
    genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(gameId, "state")), state);
    genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(gameId, "claimTime")), 0);
  }

/**
 * @dev store the total debit by an a/c per game
 */
  function setTotalDebit(
    uint _gameId, address _account, uint _eth_amount, uint _kty_amount
  ) external
    onlyContract(CONTRACT_NAME_ENDOWMENT_FUND)
    //onlyExistingProfile(_account)
    onlyExistingHoneypot(_gameId)
    returns (bool) {

    if (_eth_amount > 0) {

      bytes32 ethTotalDebitPerGamePerAcKey = keccak256(abi.encodePacked(_gameId, _account, "ethDebit"));
      uint ethTotal = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, ethTotalDebitPerGamePerAcKey);
      genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, ethTotalDebitPerGamePerAcKey, ethTotal.add(_eth_amount));

    }

    if (_kty_amount > 0) {

      bytes32 ktyTotalDebitPerGamePerAcKey = keccak256(abi.encodePacked(_gameId, _account, "ktyDebit"));
      uint ktyTotal = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, ktyTotalDebitPerGamePerAcKey);
      genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, ktyTotalDebitPerGamePerAcKey, ktyTotal.add(_kty_amount));

    }

  return true;
  }


/**
 * @dev get total debit by an a/c per game
 */
  function getTotalDebit(
    uint _gameId, address _account
  ) external view
    onlyContract(CONTRACT_NAME_ENDOWMENT_FUND)
    //onlyExistingProfile(_account)
    onlyExistingHoneypot(_gameId)
    returns (uint256 ethTotalDebit, uint256 ktyTotalDebit) {
      bytes32 ethTotalDebitPerGamePerAcKey = keccak256(abi.encodePacked(_gameId, _account, "ethDebit"));
      bytes32 ktyTotalDebitPerGamePerAcKey = keccak256(abi.encodePacked(_gameId, _account, "ktyDebit"));
      ethTotalDebit = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, ethTotalDebitPerGamePerAcKey);
      ktyTotalDebit = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, ktyTotalDebitPerGamePerAcKey);
  }


  modifier onlyExistingHoneypot(uint gameId) {
    require(genericDB.doesNodeExist(CONTRACT_NAME_ENDOWMENT_DB, TABLE_KEY_HONEYPOT, gameId), ERROR_DOES_NOT_EXIST);
    _;
  }

  modifier onlyExistingProfile(address account) {
    require(genericDB.doesNodeAddrExist(CONTRACT_NAME_PROFILE_DB, TABLE_KEY_PROFILE, account), ERROR_NOT_REGISTERED);
    _;
  }
}

