const EthieToken = artifacts.require('EthieToken');

contract('EthieToken', (accounts) => {
    let keth;

    before(async () => {
        keth = await EthieToken.new();
    });

    it('should return correct name', async () => {
        let ethAmount = 12.3456;
        let lockTime = Math.round(Date.now()/1000)+24*60*60;
        await keth.mint(accounts[1], web3.utils.toWei(String(ethAmount)), lockTime);
        let tokenId = await keth.tokenOfOwnerByIndex(accounts[1], 0);
        let name = await keth.name(tokenId);
        let expected = String(ethAmount)+"ETH_G0_LOCK"+lockTime+"_"+tokenId;
        assert.equal(name, expected);
    });

});
