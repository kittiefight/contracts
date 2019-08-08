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
    event JobDeleted(uint256 jobId, address contractAddress);
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
     * @return id of added Job
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
     * @return id of added Job
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
     * @notice Use this function to delete Job
     * 
     * @param contractName Name of the contract which executes Job
     * @param jobId Job to delete
     */
    function deleteCronJob(
        string calldata contractName,
        uint256 jobId
    )
        external onlyContract(contractName)
    {
        (/*uint256 time*/, string memory jobContractName, /*bytes memory data*/) = getJob(jobId);
        _checkSenderAndDeleteJob(jobId, contractName, jobContractName);
    }
    /**
     * @notice Use this function to reschedule Job
     * 
     * @param contractName Name of the contract which executes Job
     * @param jobId Original Job (which will be deleted)
     * @param newTime Timestamp when (or after this time) Job should be executed
     *
     * @dev Original Job will be deleted, New Job created with same data
     */
    function rescheduleCronJob(
        string calldata contractName,
        uint256 jobId,
        uint256 newTime
    )
        external onlyContract(contractName)
        returns(uint256)
    {
        (/*uint256 time*/, string memory jobContractName, bytes memory data) = getJob(jobId);
        _checkSenderAndDeleteJob(jobId, contractName, jobContractName);
        uint256 nextJob = (getLastScheduledJobTime() <= newTime)?0:findNextJob(newTime);
        uint256 newJobId = addJob(newTime, contractName, data, nextJob);
        emit JobAdded(newJobId, contractName, data);
        return newJobId;
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
        /*(bool success, bytes memory result) = */ _executeJob(nextJob);
        removeJob(nextJob);
        return (true, nextJob);
    }

    function executeJobManually(uint256 jobId) external onlyOwner returns(bool, bytes memory){
        return _executeJob(jobId);
    }
    function executeJob(uint256 jobId) external onlyProxy returns(bool, bytes memory){
        return _executeJob(jobId);
    }
    function _executeJob(uint256 jobId) internal returns(bool, bytes memory){
        (uint256 time, string memory contractName, bytes memory data) = getJob(jobId);
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

    function _checkSenderAndDeleteJob(uint256 jobId, string memory senderContractName, string memory jobContractName) private {
        require(keccak256(abi.encodePacked(jobContractName)) == keccak256(abi.encodePacked(senderContractName)), 'Can only delete the job you created');
        removeJob(jobId);
        emit JobDeleted(jobId, msg.sender); //msg.sender should be the address of contractName, this is ensured by onlyContract() modifier on public function which calls this
    }

}
