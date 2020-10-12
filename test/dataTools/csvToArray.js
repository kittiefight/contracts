const fs = require("fs");
const path = require("path");
const csv = require("fast-csv");

const BigNumber = require('bignumber.js')

// node test/dataTools/csvToArray.js "investments2.csv" privateSaleAddress ''

// if want to exclude an address, put the address inside ''
// if there are more than 1 address to exclude, list all addresses inside '' separated by comma,
// without any space. Example:
// node test/dataTools/csvToArray.js "investments2.csv" '0x258ac32ad0b0806c9ecc9d2cc58dd7f66314b2b5,0xfd0d518b68f0d40ef6f14f68e7298b0418a09c2a'

let file = process.argv[2]
let privateSaleAddr = process.argv[3]
let removeAddrs = process.argv[4].split(',')

console.log("====================== EtherScan Investment File ======================")
console.log('\n======================  addresses ======================\n')

let addressArray = [];
let ethArray = []

function addInvestment(addr, eth) {
  if ( addr.toLowerCase() == privateSaleAddr.toLowerCase() ) {
    return;
  }
    if (eth == 0) {
      return;
    }
    for (let i=0; i<removeAddrs.length; i++) {
        if (addr == removeAddrs[i]) {
            return;
        }
    }
  addressArray.push(addr);
  let x = new BigNumber(eth)
  ethArray.push(x.times(1000000000000000000));
}

fs.createReadStream(path.resolve(__dirname, "csvFiles", file))
  .pipe(
    csv.parse({
      headers: true,
      discardUnmappedColumns: true,
    })
  )
  .on("error", (error) => console.error(error))
  .on("data", (row) => addInvestment(row.From, row["Value_IN(ETH)"]))
  .on("end", () => console.log(addressArray.toString(), '\n\n====================== ether amounts ======================\n', ethArray.toString()));
