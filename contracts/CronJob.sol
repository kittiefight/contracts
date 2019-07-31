/**
 * @title CronJob
 *
 * @author @kittieFIGHT @ola @pash7ka
 *
 */

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
pragma solidity ^0.5.5;

import "./modules/databases/CronJobDB.sol";



contract CronJob is CronJobDB {
    event JobAdded(uint256 jobId, string contractName, bytes data);
    event JobExecuted(uint256 jobId, address contractAddress, bytes result);
    event JobFailed(uint256 jobId, address contractAddress);

    constructor(GenericDB _genericDB) CronJobDB(_genericDB) public {
    }
    /**
     * @notice Use this function to add Job
     * 
     * @param contractName Name of the contract to execute. See /modules/proxy/ContractNames.sol
     * @param time Timestamp when (or after this time) Job should be executed
     * @param data message to the contract. Use abi.encodeWithSignature() to generate data
     * @param nextJob id of next job, if you are adding job not on the end of the list, 0 otherwise
     * 
     * @dev If you set nextJob to 0, time should be >= getLastScheduledJobTime()
     * Use findNextJob() to find out nextJob
     */
    function addCronJob(
        string calldata contractName,
        uint256 time,
        bytes calldata data,
        uint256 nextJob
    )
        external onlyContract(contractName)
        returns(uint256)
    {
        uint256 jobId = addJob(time, contractName, data, nextJob);
        emit JobAdded(jobId, contractName, data);
        return jobId;
    }

    /**
     * @notice Use this function to add Job
     * 
     * @param contractName Name of the contract to execute. See /modules/proxy/ContractNames.sol
     * @param time Timestamp when (or after this time) Job should be executed
     * @param data message to the contract. Use abi.encodeWithSignature() to generate data
     *
     * @dev Use this variant if you don't know if your new job will be the last one or not or do not want to search for nextJob youself.
     * WARNING: This may use too much gas!
     */
    function addCronJob(
        string calldata contractName,
        uint256 time,
        bytes calldata data
    )
        external onlyContract(contractName)
        returns(uint256)
    {
        uint256 nextJob = (getLastScheduledJobTime() <= time)?0:findNextJob(time);
        uint256 jobId = addJob(time, contractName, data, nextJob);
        emit JobAdded(jobId, contractName, data);
        return jobId;
    }

    /**
     * This function same as addCronJob(), but can only be called by owner.
     * It can be used to manualy re-schedule failed Job
     */
    function addCronJobManually(
        string calldata contractName,
        uint256 time,
        bytes calldata data,
        uint256 nextJob
    )
        external onlyOwner
        returns(uint256)
    {
        uint256 jobId = addJob(time, contractName, data, nextJob);
        emit JobAdded(jobId, contractName, data);
        return jobId;
    }

    /**
     * @notice Executes next available job
     * returns (true, executed_job_id) if there was a job to execute,  (false, 0) if no job is scheduled for now
     */
    function executeNextJobIfAvailable() external onlyProxy returns(bool, uint256) {
        uint256 nextJob = getFirstJobId();
        if(nextJob == 0) return (false, 0);
        (uint256 time, /*uint16 nonce*/) = parseJobID(nextJob);
        if(time > now) return (false, 0);
        /*(bool success, bytes memory result) = */ executeJob(nextJob);
        removeJob(nextJob);
        return (true, nextJob);
    }

    function executeJob(uint256 jobId) internal returns(bool, bytes memory){
        uint256 time; string memory contractName; bytes memory data;
        (time, contractName, data) = getJob(jobId);
        assert(time <= now);
        address contractAddress = proxy.getContract(contractName);
        (bool success, bytes memory returnData) = contractAddress.call(data);
        if(success){
            emit JobExecuted(jobId, contractAddress, returnData);
        }else{
            emit JobFailed(jobId, contractAddress);
            //If we stop on failed job, that will, probably, stop the whole cron system
        }
        return (success, returnData);
    }


}
