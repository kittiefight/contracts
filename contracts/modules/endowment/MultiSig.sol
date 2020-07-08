pragma solidity ^0.5.5;

/**
 * @title MultiSig Contract
 * @dev Multisig that enables 5 of 12 approvals before any funds can be moved by superadmin
        by pre-approved signers 3 of 6 from kittieFIGHT team 2 of 6 from other organizations
 */

import "../proxy/Proxied.sol";
import "../../authority/Guard.sol";
import '../../libs/SafeMath.sol';

contract MultiSig is Proxied, Guard {
    using SafeMath for uint256;

    address[] public team;
    address[] public otherOrg;

    mapping(address => bool) signed;

    uint256 public requiredTeam;
    uint256 public requiredOtherOrg;

    string constant ACTION_MESSAGE = "Your action here";

    uint256 public countTeam;
    uint256 public countOtherOrg;

    constructor(address[] memory _team, address[] memory _otherOrg) public onlyOwner {
        for (uint256 i = 0; i < _team.length; i++) {
            team.push(_team[i]);
        }

        for (uint256 j = 0; j < _otherOrg.length; j++) {
            otherOrg.push(_otherOrg[j]);
        }

        requiredTeam = 3;
        requiredOtherOrg = 2;
    }

    event Signed(address indexed signer, uint256 time, uint256 signedTeam, uint256 signedOtherOrg);
    event ActionMessageSent(string indexed message, uint256 time);

    function sign() public onlyProxy returns (bool) {
        address msgSender = getOriginalSender();
        require(isTeam(msgSender) || isOtherOrg(msgSender), "Not authorized");
        require(signed[msgSender] == false, "Already signed");

        signed[msgSender] = true;
        if(isTeam(msgSender)) {
            countTeam += 1;
        } else if(isOtherOrg(msgSender)) {
            countOtherOrg += 1;
        }

        emit Signed(msgSender, now, countTeam, countOtherOrg);

        return true;
    }

    function action() public onlyContract(CONTRACT_NAME_ENDOWMENT_FUND) returns (string memory) {
        require(isConfirmed(), "Not confirmed yet");
        for (uint256 i = 0; i < team.length; i++) {
            if (signed[team[i]] == true) {
                signed[team[i]] = false;
            }
        }

        for (uint256 j = 0; j < otherOrg.length; j++) {
            if (signed[otherOrg[j]] == true) {
                signed[otherOrg[j]] = false;
            }
        }

        countTeam = 0;
        countOtherOrg = 0;

        emit ActionMessageSent(ACTION_MESSAGE, now);

        return ACTION_MESSAGE;
    }

    function addTeam(address _newMember) public onlyOwner returns (bool) {
        require(!isTeam(_newMember), "Already a team member in multi-sig");
        team.push(_newMember);
        return true;
    }

    function removeTeam(address _oldMember) public onlyOwner returns (bool) {
        require(isTeam(_oldMember), "Not a team member in multi-sig");
        for (uint256 i = 0; i < team.length; i++) {
            if (team[i] == _oldMember) {
                team[i] = team[team.length.sub(1)];
                break;
            }
        }
        team.length = team.length.sub(1);
        return true;
    }

    function addOtherOrg(address _newMember) public onlyOwner returns (bool) {
        require(!isOtherOrg(_newMember), "Already a member in other organizations in multi-sig");
        otherOrg.push(_newMember);
        return true;
    }

    function removeOtherOrg(address _oldMember) public onlyOwner returns (bool) {
        require(isOtherOrg(_oldMember), "Not a member in other organizations in multi-sig");
        for (uint256 i = 0; i < otherOrg.length; i++) {
            if (otherOrg[i] == _oldMember) {
                otherOrg[i] = otherOrg[team.length.sub(1)];
                break;
            }
        }
        otherOrg.length = otherOrg.length.sub(1);
        return true;
    }

    function changeRequiredTeam(uint256 _newRequired) public onlyOwner returns (bool) {
        require(_newRequired != requiredTeam, "Same required number");
        require(_newRequired > 0 && _newRequired <= team.length, "Incorrect required number");

        requiredTeam = _newRequired;
    }

    function changeRequiredOtherOrg(uint256 _newRequired) public onlyOwner returns (bool) {
        require(_newRequired != requiredOtherOrg, "Same required number");
        require(_newRequired > 0 && _newRequired <= otherOrg.length, "Incorrect required number");

        requiredOtherOrg = _newRequired;
    }

    function isTeam(address _signer) public view returns (bool) {
        for (uint256 i = 0; i < team.length; i++) {
            if (_signer == team[i]) {
                return true;
            }
        }
        return false;
    }

    function isOtherOrg(address _signer) public view returns (bool) {
        for (uint256 i = 0; i < otherOrg.length; i++) {
            if (_signer == otherOrg[i]) {
                return true;
            }
        }
        return false;
    }

    function isConfirmed() public view returns (bool) {
        uint256 signedTotal = countTeam.add(countOtherOrg);
        uint256 total = team.length.add(otherOrg.length);
        if (countTeam >= requiredTeam && countOtherOrg >= requiredOtherOrg && signedTotal <= total) {
            return true;
        }
        return false;
    }

}