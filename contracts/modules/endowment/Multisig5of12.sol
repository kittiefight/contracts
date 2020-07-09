pragma solidity ^0.5.5;

/**
 * @title MultiSig Contract
 * @dev  simulating 5 0f 12 multi-sig distributing trust externally.
 *       3 required signatures from KittieFIGHT
 *       2 required signatures from external organizations
 */

import "../proxy/Proxied.sol";
import "../../authority/Guard.sol";
import "../../libs/SafeMath.sol";

contract Multisig5of12 is Proxied, Guard {
    using SafeMath for uint256;

    uint256 public requiredSigKittieFight;
    uint256 public requiredSigExternal;
    uint256 public totalRequiredSigs;

    // transfers information
    struct Transfer {
        //uint256 transferNumber;
        uint256 approvalCount;
        uint256 kittieFightSignatures;
        uint256 externalSignatures;
        bool transferApproved;
        address newEscrow;
    }

    // map the transferNumber to a transfer
    mapping(uint256 => Transfer) transfers;

    // a list of all signedTransfers with referrence to transferNumber
    uint256[] signedTransfers;

    struct Signer {
        //address addr;
        string name;
        string organization;
        bool approved;
    }

    mapping(address => Signer) signers;

    // a list of all approved signers
    address[] allSigners;
    // a list of all approved kittieFight signers
    address[] allKittieFightSigners;
    // a list of all approved external signers
    address[] allExternalSigners;

    //mapping(string => Singer[]) signerGroups;

    constructor() public {
        requiredSigKittieFight = 3;
        requiredSigExternal = 2;
        totalRequiredSigs = 5;
    }

    event Signup(
        string indexed organization,
        string indexed name,
        address indexed signer
    );
    event ApproveTranser(address indexed signer, uint256 transferNumber);
    event ApproveSigner(address indexed signer, string indexed organization);
    event RemoveSigner(address indexed signer);

    function updateThresholdSig(
        uint256 _requiredSigKittieFight,
        uint256 _requiredSigExternal,
        uint256 _totalRequiredSig
    ) public onlySuperAdmin {
        requiredSigKittieFight = _requiredSigKittieFight;
        requiredSigExternal = _requiredSigExternal;
        totalRequiredSigs = _totalRequiredSig;
    }

    function signup(string memory _name, string memory _organization)
        public
        onlyProxy
    {
        address msgSender = getOriginalSender();
        Signer memory signer;
        signer.name = _name;
        signer.organization = _organization;
        signers[msgSender] = signer;
        emit Signup(_organization, _name, msgSender);
    }

    function approveSigner(address _addr, string memory _organization)
        public
        onlySuperAdmin
    {
        signers[_addr].organization = _organization;
        signers[_addr].approved = true;

        if (isKittieFight(_organization)) {
            allKittieFightSigners.push(_addr);
        } else {
            allExternalSigners.push(_addr);
        }

        allSigners.push(_addr);

        emit ApproveSigner(_addr, _organization);
    }

    function refuteSigner(address _addr) public onlySuperAdmin {
        signers[_addr].approved = false;
        string memory _organization = signers[_addr].organization;
        if (isKittieFight(_organization)) {
            for (uint256 i = 0; i < allKittieFightSigners.length; i++) {
                if (allKittieFightSigners[i] == _addr) {
                    allKittieFightSigners[i] = allKittieFightSigners[allSigners
                        .length
                        .sub(1)];
                }
            }
            allKittieFightSigners.length = allKittieFightSigners.length.sub(1);
        } else {
            for (uint256 i = 0; i < allExternalSigners.length; i++) {
                if (allExternalSigners[i] == _addr) {
                    allExternalSigners[i] = allExternalSigners[allSigners
                        .length
                        .sub(1)];
                }
            }
            allExternalSigners.length = allExternalSigners.length.sub(1);
        }
        for (uint256 i = 0; i < allSigners.length; i++) {
            if (allSigners[i] == _addr) {
                allSigners[i] = allSigners[allSigners.length.sub(1)];
            }
        }
        allSigners.length = allSigners.length.sub(1);

        emit RemoveSigner(_addr);
    }

    function approveTransfer(uint256 _transferNum, address _newEscrowAddr)
        public
        onlyProxy
        returns (bool)
    {
        address msgSender = getOriginalSender();
        require(signers[msgSender].approved == true, "Not an approved signer");
        transfers[_transferNum].newEscrow = _newEscrowAddr;
        transfers[_transferNum].approvalCount = transfers[_transferNum]
            .approvalCount
            .add(1);
        if (isKittieFight(signers[msgSender].organization)) {
            transfers[_transferNum]
                .kittieFightSignatures = transfers[_transferNum]
                .kittieFightSignatures
                .add(1);
        } else {
            transfers[_transferNum].externalSignatures = transfers[_transferNum]
                .externalSignatures
                .add(1);
        }
        if (
            transfers[_transferNum].kittieFightSignatures >=
            requiredSigKittieFight &&
            transfers[_transferNum].externalSignatures >= requiredSigExternal
        ) {
            transfers[_transferNum].transferApproved = true;
            signedTransfers.push(_transferNum);
        }
        emit ApproveTranser(msgSender, _transferNum);
        return true;
    }

    // return true if transfer is approved
    function isTransferApproved(uint256 _transferNum)
        public
        view
        returns (bool)
    {
        if (_transferNum == 0) {
            return true;
        }

        if (transfers[_transferNum].transferApproved) {
            return true;
        }

        return false;
    }

    // return true if _organization is kittieFight
    function isKittieFight(string memory _organization)
        public
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(_organization)) ==
            keccak256(abi.encodePacked("kittieFight"));
    }

    // get a list of all approved signger
    function getSigners() public view returns (address[] memory) {
        return allSigners;
    }

    // get a list of all approved kittieFight signers
    function getSignersKittieFight() public view returns (address[] memory) {
        return allKittieFightSigners;
    }

    // return a list of all approved external signers
    function getSignersExternal() public view returns (address[] memory) {
        return allExternalSigners;
    }
}
