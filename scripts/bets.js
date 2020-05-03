const GameManager = artifacts.require('GameManager')
const KFProxy = artifacts.require('KFProxy')
const GMGetterDB = artifacts.require('GMGetterDB')

function setMessage(contract, funcName, argArray) {
    return web3.eth.abi.encodeFunctionCall(
        contract.abi.find((f) => { return f.name == funcName; }),
        argArray
    );
}

function randomValue() {
    return Math.floor(Math.random() * 1000) + 1; // (1-num) value
}

function randomBet(maxBet) {
    return Math.floor(((Math.random() * maxBet) + 0.0001) * 10000) / 10000;
}


//truffle exec scripts/bets.js <accountIndex> <timesToBet> <maxBetAmount> --network rinkeby

module.exports = async (callback) => {
    try {
        proxy = await KFProxy.deployed()
        gameManager = await GameManager.deployed()
        getterDB = await GMGetterDB.deployed();

        let gameId = 14;
        let accountIndex = process.argv[4];
        let timesToBet = process.argv[5];
        let maxBetAmount = process.argv[6];

        let allAccounts = await web3.eth.getAccounts();

        let account = allAccounts[accountIndex];



        for (i = 0; i < timesToBet; i++) {

            let info = await getterDB.getSupporterInfo(gameId, account);
            let players = await getterDB.getGamePlayers(gameId);

            let supporting;

            if (info.supportedPlayer === players.playerBlack) supporting = 'BLACK';
            else supporting = 'RED';

            let amountBet = randomBet(maxBetAmount);

            console.log(`Betting ${amountBet} ETH...`)
            proxy.execute('GameManager', setMessage(gameManager, 'bet',
                [gameId, randomValue()]), { from: account, value: web3.utils.toWei(String(amountBet)) })
                .then(() => {
                    console.log(`Player ${account} placed a bet in game ${gameId} for ${supporting}!\n`)
                })
            proxy.execute('GameManager', setMessage(gameManager, 'bet',
                [gameId, randomValue()]), { from: account, value: web3.utils.toWei(String(amountBet)) })
                .then(() => {
                    console.log(`Player ${account} placed a bet in game ${gameId} for ${supporting}!\n`)
                })
            await proxy.execute('GameManager', setMessage(gameManager, 'bet',
                [gameId, randomValue()]), { from: account, value: web3.utils.toWei(String(amountBet)) })
                .then(() => {
                    console.log(`Player ${account} placed a bet in game ${gameId} for ${supporting}!\n`)
                })

        }

        callback()
    }
    catch (e) { callback(e) }

}
