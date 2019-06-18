pragma solidity ^0.5.5;

import "../modules/proxy/Proxied.sol";
import "../CronJob.sol";

/**
 * @title Contract for testing CronJob
 * @author pash7ka
 */
contract ProxyMock is KFProxy {
    function callContract(string memory contractName, bytes memory data) onlyOwner public returns(bytes memory) {
        address contrct = getContract(contractName);
        (bool success, bytes memory returnData) = contrct.call(data);
        require(success);
        return returnData;
    }
    function scheduleJob(string memory contractName, uint256 timestamp, bytes memory data, uint256 nextJob) onlyOwner public returns(uint256) {
        CronJob cron = CronJob(getContract(CONTRACT_CRONJOB));
        return cron.addCronJob(contractName, timestamp, data, nextJob);
    }
}
