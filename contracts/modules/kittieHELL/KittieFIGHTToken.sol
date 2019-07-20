pragma solidity >=0.5.0 <0.6.0;

/// @title A dummy token
/// @author A dummy
/// @dev A dummy token for testing purposes.

contract KittieFIGHTToken {
    string public name = "Kittie Fight Token";
    string public symbol = "KTY";
    address public founder;
    uint public totalSupply;
      
    mapping(address => uint) public balances;

    constructor() public payable {
        totalSupply = 1e18;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }

    function transferFrom(address _from, address _to, uint _tokens) public payable returns(bool){
       // require(allowed[_from][_to] >= _tokens);
        require(balances[_from] >= _tokens);
        
        balances[_from] -= _tokens;
        balances[_to] += _tokens;
        
        
        //allowed[_from][_to] -= _tokens;
        
        return true;
    }


}
