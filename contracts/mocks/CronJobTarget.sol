pragma solidity ^0.5.5;

import "../modules/proxy/Proxied.sol";
import "../CronJob.sol";

/**
 * @title Contract for testing CronJob
 * @author pash7ka
 */
contract CronJobTarget is Proxied {
	uint256 public value;
    uint256 public scheduledJob;
    event Scheduled(uint256 scheduledJob, uint256 time, uint256 value);
    event Rescheduled(uint256 scheduledJob, uint256 newDelay);

    function scheduleSetNonZeroValue(uint256 _value, uint256 _delay) public onlyOwner() {
        require(_value > 0, 'Value should be > 0');

        CronJob cron = CronJob(proxy.getContract(CONTRACT_NAME_CRONJOB));
        scheduledJob = cron.addCronJob("CronJobTarget", now+_delay, abi.encodeWithSignature("setNonZeroValue(uint256)", _value));
        emit Scheduled(scheduledJob, now+_delay, _value);
    }

    function setNonZeroValue(uint256 _value) public onlyContract(CONTRACT_NAME_CRONJOB) {
        require(_value > 0, "Value should not be zero");
        value = _value;
    }

    function setZeroValueOrRechedule(uint256 _delay) public onlyContract(CONTRACT_NAME_CRONJOB) {
        if(_delay == 0) {
            value = 0;
            scheduledJob = 0;
            return;
        }

        CronJob cron = CronJob(proxy.getContract(CONTRACT_NAME_CRONJOB));
        uint256 newDelay = _delay/2;
        if(newDelay < 5) newDelay = 0;
        scheduledJob = cron.addCronJob("CronJobTarget", now+_delay, abi.encodeWithSignature("setZeroValueOrRechedule(uint256)", newDelay), 0);
        emit Rescheduled(scheduledJob, newDelay);
    }


}