pragma solidity ^0.4.18;

contract Token{
    function balanceOf(address _owner) constant returns (uint256);
    function transfer(address _to, uint256 _value) returns (bool);
}

contract ERCReady{
    address public tokenWithdrawalAddress;
    //Allow Retreival of indicated tokens from the contract to the owner
    function ERCReady(address _addr) public {
      tokenWithdrawalAddress = _addr;
    }

    function updateWithdrawalAddress(address _addr) public {
      require(tokenWithdrawalAddress == msg.sender);
      require(_addr != 0x0);
      tokenWithdrawalAddress = _addr;
    }

    function withdraw(address _addr) public {
      Token token = Token(_addr);
      uint bal = token.balanceOf(this);
      token.transfer(tokenWithdrawalAddress,bal);
    }
}
