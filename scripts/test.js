const GenericDB = artifacts.require('GenericDB');
const GameVarAndFee = artifacts.require('GameVarAndFee')

module.exports = async (callback) => {

    genericDB = await GenericDB.deployed()
    gameVarAndFee = await GameVarAndFee.deployed()

    let numMatches = await gameVarAndFee.getRequiredNumberMatches();
    console.log('GenericDB Address:', genericDB.address);
    console.log('Required Number of Matches:', numMatches.toString());
    callback()

}