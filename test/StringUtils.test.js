const StringUtilsTest = artifacts.require('StringUtilsTest');

contract('StringUtilsTest', (accounts) => {
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

    it('should convert unsigned integer to string', async () => {
        let x = Math.round(Math.random()*100000);
        let expected = String(x);
        let result = await contract.fromUint256(x);
        assert.equal(result, expected, "Number is incorrectly converted");
    });
});
