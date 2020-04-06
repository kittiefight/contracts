const StringUtilsTest = artifacts.require('StringUtilsTest');

contract('StringUtilsTest', (owner, otherAccounts) => {
    let contract;

    before(async () => {
        contract = await StringUtilsTest.new();
    });

    it('should concat two strings', async () => {
        let a = "string 1";
        let b = "string 2";
        let expected = a+b;
        let result = await contract.concat(a, b);
        assert.equal(result, expected, "Strings are incorrectly concatenated");
    });
});
