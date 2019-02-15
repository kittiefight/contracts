pragma solidity 0.4.21;


/**
 * @title BasicControls
 * @dev this contract implement basic controls needed in a variety of contracts
 */
contract BasicControls {

    /**
     * @dev assemble the given address bytecode. If bytecode exists then the `_addr` is a contract.
     * @param _addr the given address to check
     * @return true or false if the address is a contract or not
     */
    function isContract(address _addr) internal view returns (bool) {
        // retrieve the size of the code on target address, this needs assembly
        uint length;
        assembly { length := extcodesize(_addr) }
        return length > 0;
    }
}
