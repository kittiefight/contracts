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
    view returns (uint state)
  {
    return genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(gameId, "state")));
  }

  function getHoneypotStateChangeTime(uint gameId) external view returns (uint stateChangeTime) {
    return genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(gameId, "stateChangeTime")));
  }

  function setHoneypotState( uint gameId, uint state ) external {
    genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(gameId, "state")), state);
    genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(gameId, "stateChangeTime")), block.timestamp);
  }

  function getHoneypotTotalETH(
    uint gameId
  )
    external
    view returns (uint ethTotal)
  {
    return genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(gameId, "ethTotal")));
  }

  function getHoneypotTotalKTY(
    uint gameId
  )
    external
    view returns (uint ktyTotal)
  {
    return genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, keccak256(abi.encodePacked(gameId, "ktyTotal")));
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
    onlyExistingProfile(account)
    onlyExistingHoneypot(gameId)
    returns (bool) {

    if (ethContribution > 0) {
      // add account into list of ETH participants of honeypot
      bytes32 ethContributionKey = keccak256(abi.encodePacked(gameId, TABLE_NAME_CONTRIBUTION_ETH));
      genericDB.pushNodeToLinkedListAddr(CONTRACT_NAME_ENDOWMENT_DB, ethContributionKey, account);

      // set new balance of the honeypot of endowment fund
      bytes32 ethTotalKey = keccak256(abi.encodePacked(gameId, "ethTotal"));
      uint ethTotal = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, ethTotalKey);
      genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, ethTotalKey, ethTotal.add(ethContribution));

      // now set account's balance within a game in endowment fund
      bytes32 ethBalanceKey = keccak256(abi.encodePacked(gameId, account, "ethBalance"));
      uint ethBalance = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, ethBalanceKey);
      genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, ethBalanceKey, ethBalance.add(ethContribution));
      return true;
    }

    // removing gameid
    if (ktyContribution > 0) {
      genericDB.pushNodeToLinkedListAddr(CONTRACT_NAME_ENDOWMENT_DB, TABLE_NAME_CONTRIBUTION_KTY, account);

      // set new balance of the KTY in the endowment fund contract
      bytes32 ktyTotalKey = keccak256(abi.encodePacked("ktyTotal"));
      uint ktyTotal = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, ktyTotalKey);
      genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, ktyTotalKey, ktyTotal.add(ktyContribution));

      // now set account's balance within a game in the endowment fund contract
      bytes32 ktyBalanceKey = keccak256(abi.encodePacked(account, "ktyBalance"));
      uint ktyBalance = genericDB.getUintStorage(CONTRACT_NAME_ENDOWMENT_DB, ktyBalanceKey);
      genericDB.setUintStorage(CONTRACT_NAME_ENDOWMENT_DB, ktyBalanceKey, ktyBalance.add(ktyContribution));
      return true;
    }

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
