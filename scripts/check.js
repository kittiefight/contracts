const GameVarAndFee = artifacts.require("GameVarAndFee");
const RoleDB = artifacts.require("RoleDB");
const Escrow = artifacts.require("Escrow");
const KFProxy = artifacts.require("KFProxy");
const DateTime = artifacts.require("DateTime");
const GameManager = artifacts.require("GameManager");

function formatDate(timestamp) {
  let date = new Date(null);
  date.setSeconds(timestamp);
  return date.toTimeString().replace(/.*(\d{2}:\d{2}:\d{2}).*/, "$1");
}

module.exports = async callback => {
  try {
    gameManager = await GameManager.deployed();
    gameVarAndFee = await GameVarAndFee.deployed();
    roleDB = await RoleDB.deployed();
    escrow = await Escrow.deployed();
    proxy = await KFProxy.deployed();
    dateTime = await DateTime.deployed();

    accounts = await web3.eth.getAccounts();

    let numMatches = await gameVarAndFee.getRequiredNumberMatches();
    let minSupporters = await gameVarAndFee.getMinimumContributors();
    let balanceKTY = await escrow.getBalanceKTY();
    let balanceETH = await escrow.getBalanceETH();
    let isSuperAdmin = await roleDB.hasRole("super_admin", accounts[0]);
    let isAdmin = await roleDB.hasRole("admin", accounts[0]);
    let addressOfGameManager = await proxy.getContract("GameManager");
    let blockchainTime = await dateTime.getBlockTimeStamp();

    console.log(" GameManger Contract Address:", gameManager.address);
    console.log(" Blockchain Time:", formatDate(blockchainTime));
    console.log(" Game Manager Address in json file:", gameManager.address);
    console.log(" Game Manager Address stored in Proxy:", addressOfGameManager);
    console.log(" Required Number of Matches:", numMatches.toString());
    console.log(" Min amount of supporters:", minSupporters.toString());
    console.log(
      " Endowment/Escrow balance :",
      String(web3.utils.fromWei(balanceETH)),
      "ETH"
    );
    console.log(
      " Endowment/Escrow balance :",
      String(web3.utils.fromWei(balanceKTY)),
      "KTY"
    );
    console.log("", accounts[0], isSuperAdmin ? "IS" : "IS NOT", "super admin");
    console.log("", accounts[0], isAdmin ? "IS" : "IS NOT", "admin");

    callback();
  } catch (e) {
    callback(e);
  }
};
