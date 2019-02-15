pragma solidity ^0.4.18;

import '../libraries/SafeMath.sol';
import '../interfaces/PromissoryToken.sol';
import '../interfaces/BountyDB.sol';
import './ERCReady.sol';


contract DaoState is ERCReady{
    using SafeMath for uint;

    uint constant public isBootrappedState = 1;
    uint constant public isFundedState = 2;
    uint constant public isLiveState = 3;

    address public boostrappedAdmin = 0x5b44efc8e385371f524e508475ebe741a3858fdc;
    address isFundedAdmin;
    address isLiveAdmin;

    BountyDB public bountyDB ;
    PromissoryToken public promissory;

    mapping(bytes32 => DappData) Dapps;


    // superdao default state.
    uint internal state = isBootrappedState;

    struct DappData {
       address DappController;
       bytes32 dappName;
       bytes32 tokenName;
       address tokenAddress;
       address dividendPool;
    }


  function DaoState(address _promisoryAddress, address _bountyDB) ERCReady(boostrappedAdmin){
    if (msg.sender != boostrappedAdmin) selfdestruct;
    promissory = PromissoryToken (_promisoryAddress);
    bountyDB = BountyDB (_bountyDB );
  }

  function SetDB(address _bountyDB) public onlyBoostrappedAdmin onlyDAOAdminContract {
    bountyDB = BountyDB(_bountyDB);
  }

  function registerDapp(address _dappController, bytes32 _dappName, bytes32 _tokenName, address _tokenAddress, address _dividendPool) public
  onlyBoostrappedAdmin onlyDAOAdminContract returns (bool success) {
      Dapps[_dappName] = DappData(_dappController, _dappName,  _tokenName, _tokenAddress, _dividendPool);
      return true;
  }

  function updateDappAttr(address _dappController, bytes32 _dappName, bytes32 _tokenName, address _tokenAddress, address _dividendPool) public
  onlyBoostrappedAdmin onlyDAOAdminContract returns (bool success) {
      Dapps[_dappName] = DappData(_dappController, _dappName,  _tokenName, _tokenAddress, _dividendPool);
      return true;
  }

  function fetchDapp(bytes32 _dappname) public view returns (address _dappController, bytes32 _dappName, bytes32 _tokenName, address _tokenAddress, address _dividendPool){
      _dappController = Dapps[_dappname].DappController;
      _dappName = Dapps[_dappname].dappName;
      _tokenName = Dapps[_dappname].tokenName;
      _tokenAddress = Dapps[_dappname].tokenAddress;
      _dividendPool = Dapps[_dappname].dividendPool;
  }



  /**
  ERC READY UPdate function
  */
  function withdrawTo(address _tokenAddr,address _addr) public {
    require(msg.sender == tokenWithdrawalAddress);
    Token token = Token(_tokenAddr);
    uint bal = token.balanceOf(this);
    token.transfer(_addr,bal);
  }

   function promissoryCheckBalance(address _backerAddress, uint _index) internal view returns  (PromissoryToken.backerData){
       uint tokenPrice;
       uint tokenAmount;
       bytes32 privateHash;
       bool prepaid;
       bool claimed;
       (tokenPrice,tokenAmount,privateHash,prepaid,claimed) = promissory.checkBalance(_backerAddress,_index);
       return PromissoryToken.backerData(tokenPrice,tokenAmount,privateHash,prepaid,claimed,0);
   }

   function getContribution(address _backerAddress, uint256 _index) public view returns (uint tokenAmount){
     return promissoryCheckBalance(_backerAddress,_index).tokenAmount;
   }

    function getContributionsCount(address _backerAddress) public view returns (uint length){
      length = 0;
      bool claimed = promissoryCheckBalance(_backerAddress,length).claimed;
      while(claimed == true){
        length++;
        claimed = promissoryCheckBalance(_backerAddress,length).claimed;
      }
    }

    function getBackerTotalPromissory(address _backerAddress,uint _count) public view returns (uint total){
      total = 0;
      for(uint c = 0;c < _count; c++){
        uint stTotal = getContribution(_backerAddress,c);
        total = SafeMath.add(total,stTotal);
        assembly {
           total := add(total, stTotal)
           }
      }
    }

   function getPromissoryBackersCount() public view returns (uint length){
     length = 0;
     address backer = promissory.backersAddresses(length);
     while(backer != 0x0){
       length++;
       backer = promissory.backersAddresses(length);
     }
   }

    function getState() public constant returns (uint) {
      return state;
    }

    function getFounder() public view returns (address){
      return promissory.founder();
    }

    function getCoFounder() public view returns (address){
      return promissory.cofounder();
    }

    function isBacker(address _addr) public view returns (bool isBacker){
      return (getContribution(_addr,0) > 0);
    }

    //only callable by consensusX contract voting outcome
    //moves the global state to the next state
    function nextState(address _nextAdmin) public onlyBoostrappedAdmin onlyDAOAdminContract returns(uint state){
        if (state == isBootrappedState) {
            state = isFundedState;
            isFundedAdmin = _nextAdmin;
        } else if (state == isFundedState) {
            state = isLiveState;
            isLiveAdmin = _nextAdmin;
        } else {
            throw;
        }

        return state;
    }

    function checkAdmin() public constant returns (address upDatedAddress){
      //address[] templist = promissory.previousFounders();
      //address lastAddress = templist[templist.length];
      //if(lastAddress =='0x0'){
      //  return boostrappedAdmin;
      //}else
      //return lastAddress;

    }

    function totalTokens(address _backerAddress) public constant returns (uint total){
      uint contributionCount = getContributionsCount(_backerAddress);
      uint PromissoryTokens = getBackerTotalPromissory(_backerAddress,contributionCount);
      uint bountyTokens = bountyDB.getTokens (_backerAddress);
      return PromissoryTokens + bountyTokens;
    }

	 /*
     * Safeguard function.
     * This function gets executed if a transaction with invalid data is sent to
     * the contract or just ether without data.
     */
    function () {
        throw;
    }

    modifier onlyBoostrappedAdmin() {
        require((msg.sender == boostrappedAdmin) && (state != isFundedState) && ( state != isLiveState));
        _;
    }

    modifier onlyDAOAdminContract() {
        require(( state != isBootrappedState) || (msg.sender == isFundedAdmin) || (state != isLiveState));
        _;
    }

}
