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

contract FrozableProxy is ProxyBase {
    event SystemFrozen();
    event SystemUnfrozen();
    bool public frozen;

    struct Freeze {
        uint256 start;
        uint256 end;
    }
    Freeze[] public freezes;
    /**
     * @notice Used to prevent KFProxy to handle new user requests in case of emergency
     * @param _frozen set new state: true -frozen (KFProxy will revert new requests), false - unfrozen
     */
    function setFrozen(bool _frozen) external onlyOwner {
        require(frozen != _frozen);
        frozen = _frozen;
        if(frozen){
            freezes.push(Freeze({
                start: now,
                end: 0
            }));
            emit SystemFrozen();
        }else{
            freezes[freezes.length-1].end = now;
            emit SystemUnfrozen();
        }
    }
    /**
     * @notice May be used to import freezes from previous version of the contract
     * @param starts Array of Freezes starts
     * @param ends Array of Freezes ends
     * @dev end time may be > now, in this case Freeze is considered as not finished
     */
    function importFreezes(uint256[] calldata starts, uint256[] calldata ends) external onlyOwner {
        require(freezes.length == 0, 'Only allow import to empty list');
        require(starts.length == ends.length, 'Each start should have matching end');
        frozen = false;
        for(uint256 i=0; i < starts.length; i++){
            if(ends[i] > now){
                freezes.push(Freeze({
                    start: starts[i],
                    end: 0
                }));
                frozen = true;
                break;
            }else{
                freezes.push(Freeze({
                    start: starts[i],
                    end: ends[i]
                }));
            }
        }
    }
    /**
     * @notice Calculates how much time system was frozen since requested time
     * @param since timestmap which limits search of frozen periods
     */
    function getFrozenTime(uint256 since) view public returns(uint256){
        if(since >= now) return 0;
        uint256 frozenTime = 0;
        //Special handling for last freeze
        if(frozen) {
            frozenTime += now - freezes[freezes.length-1].start;
        }else if(freezes.length > 0){
            uint256 lastFreeze = freezes.length - 1;
            frozenTime += freezes[lastFreeze].end - freezes[lastFreeze].start;
        }
        //If there is more than 1 freeze, cycle through them
        if(freezes.length > 1) for(uint256 i = freezes.length-2; i >=0; i--){
            if(freezes[i].end <= since) break;
            if(freezes[i].start > since) {
                frozenTime += freezes[i].end - freezes[i].start;
            }else{
                frozenTime += freezes[i].end - since;
                break;
            }
        }
        return frozenTime;
    }

}
