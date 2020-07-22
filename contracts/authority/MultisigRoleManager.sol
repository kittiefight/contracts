pragma solidity ^0.5.5;

import "../modules/databases/RoleDB.sol";
import "./Guard.sol";

/**
 * @dev This contract should be used as a part of  some other contract that needs it, like Register
 */
contract MultisigRoleManager is Guard {
    event RoleMoveRequestCreated(uint256 indexed id, address creator, address from, address to, uint256 deadline);
    event RoleMoveRequestSigned(uint256 indexed id, address signer);
    event RoleMoveRequestExecuted(uint256 indexed id);

    struct RoleMoveRequest{
        address from;                       // Address we want to move a role from
        address to;                         // Address we want to move a role from
        string role;                        // name of the role as in SystemRoles.sol
        uint256 deadline;                   // Timestamp  when request will be expired
        uint256 requiredSignatures;         // Number of signatures required to complete action
        string signingRole;                 // Require signers to have this role, see role list in SystemRoles.sol
        uint256 signatureCount;             // How many signers already signed this request
        mapping(address=>bool) signatures;  // Map of signers    
        bool executed;
    }

    RoleMoveRequest[] public requests;

    //This functions are implemented in Register
    function _registerRole(address account, string memory role) internal;
    function _removeRole(address account, string memory role) internal;

    function createRoleMoveRequest(address from, address to, string memory role, uint256 deadline, uint256 requiredSignatures, string memory signingRole) internal returns(uint256){
        require(deadline > now, "Bad deadline");
        require(hasRole(from, role), "From address does not currently have the role");
        require(!hasRole(to, role), "To address already has the role");
        require(requiredSignatures > 1, "Should require more than 1 signature");
        requests.push(RoleMoveRequest({
            from: from,
            to: to,
            role: role,
            deadline: deadline,
            requiredSignatures: requiredSignatures,
            signingRole: signingRole,
            signatureCount: 0,
            executed: false
        }));
        uint256 id = requests.length-1;
        emit RoleMoveRequestCreated(id, getOriginalSender(), from, to, deadline);
        return id;
    }

    function signRoleMoveRequest(uint256 requestId) public { // This function does not need onlyProxy/onlyAdmin/onlySuperAdmin modifier because role is checked inside
        require(requestId < requests.length, "Bad request id");
        RoleMoveRequest storage request = requests[requestId];
        require(checkRole(request.signingRole), "Signing role required");
        require(!request.executed, "Request already executed");
        require(now <= request.deadline, "Request expired");
        address sender = getOriginalSender();
        require(!request.signatures[sender], "Already signed by this sender");
        request.signatures[sender] = true;
        request.signatureCount += 1;
        emit RoleMoveRequestSigned(requestId, sender);

        if(request.signatureCount >= request.requiredSignatures) {
            request.executed = true;
            _removeRole(request.from, request.role);
            _registerRole(request.to, request.role);
            emit RoleMoveRequestExecuted(requestId);
        }
    }

    function hasRole(address who, string memory role) private view returns (bool) {
        return RoleDB(proxy.getContract(CONTRACT_NAME_ROLE_DB)).hasRole(role, getOriginalSender());
    }

}
