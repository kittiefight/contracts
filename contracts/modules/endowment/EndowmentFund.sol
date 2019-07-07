pragma solidity ^0.5.5;

import "../proxy/Proxied.sol";
import "../databases/EndowmentDB.sol";
import "../../GameVarAndFee.sol";
import "../../interfaces/ERC20Standard.sol";

contract EndowmentFund is Proxied {

  GameVarAndFee public gameVarAndFee;
  EndowmentDB public endowmentDB;

  /// @notice  the count of all invocations of `generatePotId`.
  uint256 public potRequestCount;

  constructor() public {
    potRequestCount = 0;
    gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
    endowmentDB = EndowmentDB(proxy.getContract(CONTRACT_NAME_ENDOWMENT_DB));
  }

  /**
   * @notice Owner can call this function to update the needed contract for checking conditions.
   * @dev contract addresses are stored in proxy
   */
  function updateContracts() external onlyOwner {
    gameVarAndFee = GameVarAndFee(proxy.getContract(CONTRACT_NAME_GAMEVARANDFEE));
    endowmentDB = EndowmentDB(proxy.getContract(CONTRACT_NAME_ENDOWMENT_DB));
  }

  enum HoneypotState {
    created,
    assigned,
    gameScheduled,
    gameStarted,
    forefeited,
    claimed
  }

  struct Honeypot {
    uint gameId;
    HoneypotState state;
    string forfeitReason;
    uint dissolveTime;
    uint gameEndTime;
    uint createdTime;
    uint ktyTotal;
    uint ethTotal;
  }

  function generateHoneyPot() external onlyContract(CONTRACT_NAME_GAMEMANAGER) returns (uint, uint) {
    uint _ktyAllocated = gameVarAndFee.getTokensPerGame();
    require(endowmentDB.allocateKTY(_ktyAllocated));
    uint _ethAllocated = gameVarAndFee.getEthPerGame();
    require(endowmentDB.allocateETH(_ethAllocated));

    uint _potId = _generatePotId();
 
    Honeypot memory _honeypot;
    _honeypot.gameId = _potId;
    _honeypot.state = HoneypotState.created;
    _honeypot.createdTime = now;
    _honeypot.ktyTotal = _ktyAllocated;
    _honeypot.ethTotal = _ethAllocated;

    endowmentDB.createHoneypot(
      _honeypot.gameId,
      uint(_honeypot.state),
      _honeypot.createdTime,
      _honeypot.ktyTotal,
      _honeypot.ethTotal
    );

    return (_potId, _ethAllocated);
  }

  struct KittieTokenTx {
      address sender;
      uint value;
      bytes data;
      bytes4 sig;
  }

  function tokenFallback(address _from, uint _value, bytes calldata _data) external {
   /* tokenTx variable is analogue of msg variable of Ether transaction:
    *  tokenTx.sender is person who initiated this token transaction   (analogue of msg.sender)
    *  tokenTx.value the number of tokens that were sent   (analogue of msg.value)
    *  tokenTx.data is data of token transaction   (analogue of msg.data)
    *  tokenTx.sig is 4 bytes signature of function if data of token transaction is a function execution
    */
    KittieTokenTx memory tokenTx;
    tokenTx.sender = _from;
    tokenTx.value = _value;
    tokenTx.data = _data;
    (bytes4 _sig, uint _gameId) = abi.decode(_data, (bytes4, uint256));
    tokenTx.sig = _sig;

    require(msg.sender == address(proxy.getContract(CONTRACT_NAME_KITTIEFIGHTOKEN)));

    // invoke the target function
    (bool _ok, ) = address(this).call(abi.encodeWithSelector(tokenTx.sig, _gameId, tokenTx.sender, tokenTx.value));
    require(_ok);
  }

  function contributeKFT(uint _gameId, address _sender, uint _value) private {
    require(endowmentDB.contibuteFunds(_sender, _gameId, 0, _value));
  }

  function contributeETH(uint _gameId) external payable {
    require(endowmentDB.contibuteFunds(msg.sender, _gameId, msg.value, 0));
  }

  /** @notice  Returns a fresh unique identifier.
   *
   * @dev the generation scheme uses three components.
   * First, the blockhash of the previous block.
   * Second, the deployed address.
   * Third, the next value of the counter.
   * This ensure that identifiers are unique across all contracts
   * following this scheme, and that future identifiers are
   * unpredictable.
   *
   * @return a 32-byte unique identifier.
   */
	function _generatePotId() internal returns (uint potId) {
    return uint(keccak256(
    abi.encodePacked(blockhash(block.number - 1), address(this), ++potRequestCount)
    ));
	}
}
