const KETHToken = artifacts.require('KETHToken');

contract('KETHToken', (accounts) => {
    let keth;

    before(async () => {
        keth = await KETHToken.new();
    });

    it('should return correct name', async () => {
        let lockTime = Math.round(Date.now()/1000)+24*60*60;
        await keth.mint(accounts[1], web3.utils.toWei("12.3"), lockTime);
        let tokenId = await keth.tokenOfOwnerByIndex(accounts[1], 0);
        let name = await keth.name(tokenId);
        console.log(name);
    });

});
