pragma solidity ^0.5.5;

import "../modules/proxy/Proxied.sol";
import "../CronJob.sol";

/**
 * @title Contract for testing CronJob
 * @author pash7ka
 */
contract CronJobTarget is Proxied {
    string constant CONTRACT_NAME = "CronJobTarget";

	uint256 public value;
    uint256 public scheduledJob;
    event Scheduled(uint256 scheduledJob, uint256 time, uint256 value);

    function scheduleSetNonZeroValue(uint256 _value, uint256 _delay) public onlyOwner() {
        require(_value > 0, 'Value should be > 0');

        CronJob cron = CronJob(proxy.getContract(CONTRACT_NAME_CRONJOB));
        scheduledJob = cron.addCronJob(CONTRACT_NAME, now+_delay, abi.encodeWithSignature("setNonZeroValue(uint256)", _value));
        emit Scheduled(scheduledJob, now+_delay, _value);
    }

    function setNonZeroValue(uint256 _value) public onlyContract(CONTRACT_NAME_CRONJOB) {
        require(_value > 0, "Value should not be zero");
        value = _value;
    }


    function removeJob(uint256 jobId) public {
        CronJob cron = CronJob(proxy.getContract(CONTRACT_NAME_CRONJOB));
        cron.deleteCronJob(CONTRACT_NAME, jobId);
    }

    function rescheduleJob(uint256 jobId, uint256 _delay) public {
        CronJob cron = CronJob(proxy.getContract(CONTRACT_NAME_CRONJOB));
        cron.rescheduleCronJob(CONTRACT_NAME, jobId, now+_delay);
    }

}
