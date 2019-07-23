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

import "../../authority/Owned.sol";
import "../../CronJob.sol";

contract CronJobProxy is ProxyBase {
    event CronJobExecutionFailed(); //This is used to signal about something really unexpected happened

    uint256 public maxJobsForOneRun = 2;

    function setMaxJobsForOneRun(uint256 _maxJobsForOneRun) onlyOwner public {
        require(_maxJobsForOneRun > 0);
        maxJobsForOneRun = _maxJobsForOneRun;
    }

    /**
     * @notice Executes up to maxJobsForOneRun scheduled jobs, if available
     * @dev This can be executed by admins, but since KFProxy can not use Guard, we need to do check manually
     */
    function executeScheduledJobs() external {
        address genericDB = getContract(CONTRACT_NAME_GENERIC_DB);
        (bool success, bytes result) = genericDB.staticcall(abi.encodeWithSignature(
            "getBoolStorage(string,bytes32)",
            CONTRACT_NAME_ROLE_DB,
            keccak256(abi.encodePacked("admin", msg.sender)
        ));
        require(success, 'Failed to load role');
        bool hasRole = abi.decode(result, (bool));
        require(hasRole, 'Sender has to be an admin');

        _executeScheduledJobs();
    }
    /**
     * @notice Executes up to maxJobsForOneRun scheduled jobs, if available
     */
    function _executeScheduledJobs() internal {
        address cronJob = getContract(CONTRACT_NAME_CRONJOB);
        //if(cronJob == address(0)) return; //this can not happen because of check in ContractManager
        for(uint256 i=0; i < maxJobsForOneRun; i++){
            //Use address.call() because we need to handle failures here
            (bool success, bytes memory result) = cronJob.call(abi.encodeWithSignature('executeNextJobIfAvailable()'));
            if(success){
                (bool jobWasExecuted, /*uint256 jobId*/) = abi.decode(result, (bool, uint256));
                if(!jobWasExecuted) break;  //There is no more jobs scheduled for now
            }else{
                emit CronJobExecutionFailed();
            }
        }
    }

}
