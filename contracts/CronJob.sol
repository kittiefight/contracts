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
    event JobExecutionFailed(uint256 jobId, string contractName, address contractAddress, bytes data);

    constructor(GenericDB _genericDB) CronJobDB(_genericDB) public {
    }

    function addCronJob(
        string calldata contractName,
        uint256 time,
        bytes calldata data,
        uint256 nextJob
    )
        external onlyContract(contractName)
        returns(uint256)
    {
        return addJob(time, contractName, data, nextJob);
    }

    /**
     * @notice Executes next available job
     * returns true if there was a job to execute, false if no job is scheduled for now
     */
    function executeNextJobIfAvailable() external onlyProxy returns(bool) {
        uint256 nextJob = getFirstJobId();
        (uint256 time, uint16 nonce) = parseJobID(nextJob);
        if(time > now) return false;
        executeJob(nextJob);
        removeJob(nextJob);
        return true;
    }

    function executeJob(uint256 jobId) internal returns(bool, bytes memory){
        uint256 time; string memory contractName; bytes memory data;
        (time, contractName, data) = getJob(jobId);
        assert(time <= now);
        address contractAddress = proxy.getContract(contractName);
        (bool success, bytes memory returnData) = contractAddress.call(data);
        if(!success){
            //If we stop on failed job, that will, probably, stop the whole cron system
            emit JobExecutionFailed(jobId, contractName, contractAddress, data);
        }
        return (success, returnData);
    }


    /*
    addChroneJob(sigHash, objectID, expiringTime)
    executeChrone(sigHash,objectID,time)
    checkOrRemove(sigHash,objectID,time) internal:
    */

    


}
