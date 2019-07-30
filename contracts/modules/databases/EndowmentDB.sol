pragma solidity ^0.5.5;

import "./GenericDB.sol";
import "../proxy/Proxied.sol";
import "../../libs/SafeMath.sol";

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

  function allocateKTY(
    uint amountRequired
  )
    external
    onlyContract(CONTRACT_NAME_ENDOWMENT_FUND)
    returns (bool)
  {
    // check actual funds
    uint actualFunds = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, VAR_KEY_ACTUAL_FUNDS_KTY);
    require(actualFunds >= amountRequired, ERROR_INSUFFICIENT_FUNDS);
    // decrease actual funds
    genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, VAR_KEY_ACTUAL_FUNDS_KTY, actualFunds.sub(amountRequired));
    // increase ingame funds
    uint ingameFunds = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, VAR_KEY_INGAME_FUNDS_KTY);
    genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, VAR_KEY_INGAME_FUNDS_KTY, ingameFunds.add(amountRequired));
    return true;
  }

  function allocateETH(
    uint amountRequired
  )
    external
    onlyContract(CONTRACT_NAME_ENDOWMENT_FUND)
    returns (bool)
  {
    // check actual funds
    uint actualFunds = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, VAR_KEY_ACTUAL_FUNDS_ETH);
    require(actualFunds >= amountRequired, ERROR_INSUFFICIENT_FUNDS);
    // decrease actual funds
    genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, VAR_KEY_ACTUAL_FUNDS_ETH, actualFunds.sub(amountRequired));
    // increase ingame funds
    uint ingameFunds = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, VAR_KEY_INGAME_FUNDS_ETH);
    genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, VAR_KEY_INGAME_FUNDS_ETH, ingameFunds.add(amountRequired));
    return true;
  }

  function updateEndowmentFund(
    uint256 _kty_amount, uint256 _eth_amount, bool deductFunds
  )
    external
    onlyContract(CONTRACT_NAME_ENDOWMENT_FUND)
    returns (bool)
  {

    if (_kty_amount>0){
      uint actualFundsKTY = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, VAR_KEY_ACTUAL_FUNDS_KTY);
      if (deductFunds){
        require(actualFundsKTY >= _kty_amount, ERROR_INSUFFICIENT_FUNDS);
        genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, VAR_KEY_ACTUAL_FUNDS_KTY, actualFundsKTY.sub(_kty_amount));
      }else{ // add
        genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, VAR_KEY_ACTUAL_FUNDS_KTY, actualFundsKTY.add(_kty_amount));
      }
    }

    if (_eth_amount>0){
      uint actualFundsETH = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, VAR_KEY_ACTUAL_FUNDS_ETH);
      if (deductFunds){
        require(actualFundsETH >= _eth_amount, ERROR_INSUFFICIENT_FUNDS);
        genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, VAR_KEY_ACTUAL_FUNDS_ETH, actualFundsETH.sub(_eth_amount));
      }else{ // add
        genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, VAR_KEY_ACTUAL_FUNDS_ETH, actualFundsETH.add(_eth_amount));
      }
    }
    
    return true;
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
  }


  function getHoneypotTotal(uint _gameId) external view returns (uint256 totalEth, uint256 totalKty) {
      totalEth = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(_gameId, "ethTotal")));
      totalKty = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(_gameId, "ktyTotal")));
  }

  function dissolveHoneypot(
    uint gameId,
    uint status
  )
    external
    onlyContract(CONTRACT_NAME_ENDOWMENT_FUND)
    onlyExistingHoneypot(gameId)
  {
    require(genericDB.pushNodeToLinkedList(CONTRACT_NAME_ENDOWMENT_DB, TABLE_KEY_HONEYPOT_DISSOLVED, gameId));
    require(genericDB.removeNodeFromLinkedList(CONTRACT_NAME_ENDOWMENT_DB, TABLE_KEY_HONEYPOT, gameId));
    genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(gameId, "status")), status);
  }

  function contributeFunds(
    address account, uint gameId, uint ethContribution, uint ktyContribution
  ) external
    onlyContract(CONTRACT_NAME_ENDOWMENT_FUND)
    // onlyExistingProfile(account)
    // onlyExistingHoneypot(gameId)
    returns (bool) {

    if (ethContribution > 0) {
      // add account into list of ETH participants of honeypot
      // bytes32 ethContributionKey = keccak256(abi.encodePacked(gameId, TABLE_NAME_CONTRIBUTION_ETH));
      // genericDB.pushNodeToLinkedListAddr(CONTRACT_NAME_ENDOWMENT_DB, ethContributionKey, account);

      // set new balance of the honeypot of endowment fund
      bytes32 ethTotalKey = keccak256(abi.encodePacked(gameId, "ethTotal"));
      uint ethTotal = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, ethTotalKey);
      genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, ethTotalKey, ethTotal.add(ethContribution));

      // now set account's balance within a game in endowment fund
      // bytes32 ethBalanceKey = keccak256(abi.encodePacked(gameId, account, "ethBalance"));
      // uint ethBalance = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, ethBalanceKey);
      // genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, ethBalanceKey, ethBalance.add(ethContribution));
    }

    if (ktyContribution > 0) {
      // genericDB.pushNodeToLinkedListAddr(CONTRACT_NAME_ENDOWMENT_DB, TABLE_NAME_CONTRIBUTION_KTY, account);

      // set new balance of the KTY in the endowment fund contract
      bytes32 ktyTotalKey = keccak256(abi.encodePacked("ktyTotal"));
      uint ktyTotal = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, ktyTotalKey);
      genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, ktyTotalKey, ktyTotal.add(ktyContribution));

      // now set account's balance within a game in the endowment fund contract
      // bytes32 ktyBalanceKey = keccak256(abi.encodePacked(account, "ktyBalance"));
      // uint ktyBalance = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, ktyBalanceKey);
      // genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, ktyBalanceKey, ktyBalance.add(ktyContribution));
    }

  return true;
  }

/**
 * @dev store the total debit by an a/c per game
 */
  //function debitFunds(
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


/**
change log

2019-07-27 09:50:51 
function setHoneypotState( uint _gameId  .. was _potId as else where gameid is used

 */