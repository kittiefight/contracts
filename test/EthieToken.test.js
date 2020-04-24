const BN = require('bn.js');
const { expect } = require('chai')
  .use(require('chai-shallow-deep-equal'))
  .use(require('chai-bn')(BN))
// require('chai')
//   .use(require('chai-shallow-deep-equal'))
//   .use(require('chai-bn')(BN))
//   .expect();
//const chai = require('chai');
// chai.use(require('chai-shallow-deep-equal'));
// chai.use(require('chai-bn')(BN));



const EthieToken = artifacts.require('EthieToken');

contract('EthieToken', (accounts) => {
    let keth;

    before(async () => {
        keth = await EthieToken.new();
    });

    it('should return correct name', async () => {
        let ethAmount = 12.3456;
        let lockPeriod = 90*24*60*60;
        await keth.mint(accounts[1], web3.utils.toWei(String(ethAmount)), lockPeriod);
        let tokenId = await keth.tokenOfOwnerByIndex(accounts[1], 0);
        let name = await keth.name(tokenId);
        let expected = String(ethAmount)+"ETH_G0_LOCK"+lockPeriod+"_"+tokenId;
        assert.equal(name, expected);
    });

    it('should return correct token URI', async () => {
        let tokenId = await keth.tokenOfOwnerByIndex(accounts[1], 0);
        // let name = await keth.name(tokenId);
        // console.log("name:", name);
        let tokenURI = await keth.tokenURI(tokenId);
        // console.log("tokenURI:", tokenURI);
        let expected = "https://ethie.kittiefight.io/metadata/"+tokenId+".json";
        assert.equal(tokenURI, expected);
    });

    it('should return array of ethie ids holded by user and total ETH value', async () => {
        let lockPeriod = 90*24*60*60;
        let ethAmount1 = 34.5678;
        await keth.mint(accounts[2], web3.utils.toWei(String(ethAmount1)), lockPeriod);

        let ethAmount2 = 56.7890;
        await keth.mint(accounts[1], web3.utils.toWei(String(ethAmount2)), lockPeriod);

        let ethAmount3 = 78.9012;
        await keth.mint(accounts[2], web3.utils.toWei(String(ethAmount3)), lockPeriod);

        let expectedIds = [new BN(2), new BN(4)];
        let expectedEth = ethAmount1+ethAmount3;

        let result = await keth.allTokenOf(accounts[2]);
        expect(result['0']).to.shallowDeepEqual(expectedIds);
        expect(result['1']).to.be.bignumber.eq(web3.utils.toWei(String(expectedEth)));

    }); 
});
