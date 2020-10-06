pragma solidity ^0.5.5;

contract KittieHellStruct {
    struct KittyStatus {
        address owner; // This is the owner before the kitty got transferred to us
        uint256 deadAt; // Timestamp when the kitty is dead.
        bool dead; // This is the mortality status of the kitty
        bool playing; // This is the current game participation status of the kitty
        bool ghost; // This is set to "destroy" or permanent kill the kitty
    }

    function encodeKittieStatus(KittyStatus memory status)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                status.owner,
                status.deadAt,
                status.dead,
                status.playing,
                status.ghost
            );
    }

    function decodeKittieStatus(bytes memory encStatus)
        internal
        pure
        returns (KittyStatus memory status)
    {
        if (encStatus.length == 0) {
            status = KittyStatus({
                owner: address(0),
                deadAt: 0,
                dead: false,
                playing: false,
                ghost: false
            });
        } else {
            (
                address owner,
                uint256 deadAt,
                bool dead,
                bool playing,
                bool ghost
            ) = abi.decode(encStatus, (address, uint256, bool, bool, bool));
            status = KittyStatus(owner, deadAt, dead, playing, ghost);
        }
    }
}
