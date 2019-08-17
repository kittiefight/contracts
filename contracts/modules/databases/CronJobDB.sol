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

import "../proxy/Proxied.sol";
import "./GenericDB.sol";
import "../../libs/SafeMath.sol";


/**
 * @title CronJobDB
 * @author @psychoplasma @pash7ka
 *
 * Storage consists of a linked list of ids and data, stored in maps, wehre key is a job id.
 * Job id is created from timestamp and a nonce, which is current count of jobs for specific timestamp.
 * After adding a job, nonce for it's timestamp is incremented. When canceling a job, nonce is NOT decremented.
 *
 * This contract should not be used standalone, it is designed as a part of CronJob
 *
 * CronJobDB uses a sorted linked list of job ids (tied to the time of execution), 
 * so that nearest jobs are on the head, while latest jobs are on the tail of the list.
 */
contract CronJobDB is Proxied {
    using SafeMath for uint256;

    GenericDB public genericDB;

    bytes32 internal constant TABLE_KEY = keccak256(abi.encodePacked("CronJobList"));
    string internal constant ERROR_ALREADY_EXIST = "Job already exists";
    string internal constant ERROR_DOES_NOT_EXIST = "Job not exists";
    string internal constant ERROR_NOT_LAST = "Job can not be added, because there is other jobs after it. Use nextJob parameter.";
    string internal constant ERROR_NOT_BEFORE = "Job can not be added because it should be after specified job.";
    string internal constant ERROR_NOT_FIRST_BEFORE = "Job can not be added because it is not directly before specified job.";

    constructor(GenericDB _genericDB) public {
        setGenericDB(_genericDB);
    }

    function setGenericDB(GenericDB _genericDB) public onlyOwner {
        genericDB = _genericDB;
    }

    /**
     * @notice Generates id of the Job
     * @param time When job has to be executed
     * @param nonce Index of job scheduled to specified timestamp
     */
    function generateJobID(uint256 time, uint16 nonce) pure public returns(uint256) {
        return (time << 16) + nonce;
    }
    function parseJobID(uint256 jobId) pure public returns(uint256, uint16) {
        return (jobId >> 16, uint16(0xFFFF & jobId));
    }

    function getJobNonceForTimestamp(uint256 time) view public returns(uint16) {
        return uint16(genericDB.getUintStorage(CONTRACT_NAME_CRONJOB, keccak256(abi.encodePacked(time, "jobNonce"))));        
    }
    function incrementJobNonceForTimestamp(uint256 time) internal {
        uint16 nonce = getJobNonceForTimestamp(time);
        genericDB.setUintStorage(CONTRACT_NAME_CRONJOB, keccak256(abi.encodePacked(time, "jobNonce")), uint256(nonce+1));        
    }

    /**
     * @notice Use this to find job next to specific time
     * Should be used before calling addJob() if inserting job in the middle of the queue
     */
    function findNextJob(uint256 time) view public returns(uint256){
        uint256 jobId = generateJobID(time, getJobNonceForTimestamp(time));
        return genericDB.findNextNodeInSortedLinkedList(CONTRACT_NAME_CRONJOB, TABLE_KEY, jobId);
    }

    /**
     * @notice Returns a job, with specified id
     * @param jobId Job to view
     * @return (time, callee, data) Time of the job, target contract, message to the contract
     */
    function getJob(uint256 jobId) view public returns(uint256, string memory, bytes memory) {
        require(genericDB.doesNodeExist(CONTRACT_NAME_CRONJOB, TABLE_KEY, jobId), ERROR_DOES_NOT_EXIST);
        uint256 time; uint16 nonce;
        (time,nonce) = parseJobID(jobId);
        string memory callee = genericDB.getStringStorage(CONTRACT_NAME_CRONJOB, keccak256(abi.encodePacked(jobId, "callee")));
        bytes memory data = genericDB.getBytesStorage(CONTRACT_NAME_CRONJOB, keccak256(abi.encodePacked(jobId, "data")));
        return (time, callee, data);
    }

    /**
     * @notice Adds Job to the list
     * @param time Job should be executed at first oportunity after this time
     * @param callee Name of a contract to call
     * @param data Message to send to this contract. Use abi.encodeWithSignature() to create it
     * @param nextJob If this job should be scheduled before some other Job, it has to be specified with this parameter, otherwise it should be 0
     */
    function addJob(
        uint256 time,
        string memory callee,
        bytes memory data,
        uint256 nextJob
    ) 
        internal //external onlyContract(CONTRACT_NAME_CRONJOB)
        returns(uint256)
    {
        uint256 jobId = generateJobID(time, getJobNonceForTimestamp(time));

        validateNewJobPosition(jobId, nextJob);

        require(genericDB.insertNodeToLinkedList(CONTRACT_NAME_CRONJOB, TABLE_KEY, jobId, nextJob, false), ERROR_ALREADY_EXIST); //false means "prev" direction - insert before nextJob
        incrementJobNonceForTimestamp(time);

        genericDB.setStringStorage(CONTRACT_NAME_CRONJOB, keccak256(abi.encodePacked(jobId, "callee")), callee);
        genericDB.setBytesStorage(CONTRACT_NAME_CRONJOB, keccak256(abi.encodePacked(jobId, "data")), data);

        return jobId;
    }


    /**
     * @notice Remove Job
     * @param jobId Job to remove
     */
    function removeJob(uint256 jobId) 
        internal //external onlyContract(CONTRACT_NAME_CRONJOB) 
    {
        //require(genericDB.removeNodeFromLinkedList(CONTRACT_NAME_CRONJOB, TABLE_KEY, jobId), ERROR_DOES_NOT_EXIST);
        //Removed requirement for the job to exist, because job can delete itself while being executed.
        //TODO: Maybe this should be prevented in some other way
        // require(genericDB.removeNodeFromLinkedList(CONTRACT_NAME_CRONJOB, TABLE_KEY, jobId), ERROR_DOES_NOT_EXIST);
        genericDB.removeNodeFromLinkedList(CONTRACT_NAME_CRONJOB, TABLE_KEY, jobId);
        //TODO: Find out if we need to actually delete the job data from mappings. Test gas price for this.
    }


    function getFirstJobId() view public returns(uint256){
        (/*bool found*/, uint256 id) = genericDB.getAdjacent(CONTRACT_NAME_CRONJOB, TABLE_KEY, 0, true);    // 0 means HEAD, false means tail of the list (because GenericDB.pushNodeToLinkedList() uses true as direction)
        return id;
    }
    function getLastJobId() view public returns(uint256){
        (/*bool found*/, uint256 id) = genericDB.getAdjacent(CONTRACT_NAME_CRONJOB, TABLE_KEY, 0, false);    // 0 means HEAD, true means head of the list (because GenericDB.pushNodeToLinkedList() uses true as direction)
        return id;
    }
    function getLastScheduledJobTime() view public returns(uint256) {
        (uint256 time, /*uint16 nonce*/) = parseJobID(getLastJobId());   //If no jobs, result will be 0, which is fine.
        return time;
    }

    function validateNewJobPosition(uint256 newJobId, uint256 nextJobId) view internal {
        if(nextJobId == 0) {
            //Check that new Job is really last
            uint256 lastJobId = getLastJobId();
            require(newJobId > lastJobId, ERROR_NOT_LAST);
        } else {
            //Check that we can insert new job bebore nextJob
            require(newJobId < nextJobId, ERROR_NOT_BEFORE);
            (bool found, uint256 prevId) = genericDB.getAdjacent(CONTRACT_NAME_CRONJOB, TABLE_KEY, nextJobId, false);   // false means "before" (PREV)
            require(!found || newJobId > prevId, ERROR_NOT_FIRST_BEFORE);
        }
    }

    function getAllJobs() public view returns(uint[] memory allJobs){
        allJobs = genericDB.getAll(CONTRACT_NAME_CRONJOB, TABLE_KEY);
    }

}
