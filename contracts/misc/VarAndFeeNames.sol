/**
 * @title GameVarAndFee
 *
 * @author @wafflemakr @hamaad
 *
 */
pragma solidity ^0.5.5;

/**
 * @title Contract that stores the hash of all variable keys 
    to store in values with eternal storage
 */
contract VarAndFeeNames {

    string constant TABLE_NAME = "GameVarAndFeeTable";

    bytes32 constant REQUIRED_NUMBER_MATCHES= keccak256(abi.encodePacked(TABLE_NAME, "requiredNumberMatches"));
    bytes32 constant GAME_PRESTART          = keccak256(abi.encodePacked(TABLE_NAME, "gamePrestart"));
    bytes32 constant GAME_DURATION          = keccak256(abi.encodePacked(TABLE_NAME, "gameDuration"));
    bytes32 constant KITTIE_HELL_EXPIRATION = keccak256(abi.encodePacked(TABLE_NAME, "kittieHellExpiration"));
    bytes32 constant HONEY_POT_EXPIRATION   = keccak256(abi.encodePacked(TABLE_NAME, "honeypotExpiration"));
    bytes32 constant TOKENS_PER_GAME        = keccak256(abi.encodePacked(TABLE_NAME, "tokensPerGame"));
    bytes32 constant ETH_PER_GAME           = keccak256(abi.encodePacked(TABLE_NAME, "ethPerGame"));
    bytes32 constant GAME_TIMES             = keccak256(abi.encodePacked(TABLE_NAME, "gameTimes"));
    bytes32 constant WINNING_KITTIE         = keccak256(abi.encodePacked(TABLE_NAME, "winningKittie"));
    bytes32 constant TOP_BETTOR             = keccak256(abi.encodePacked(TABLE_NAME, "topBettor"));
    bytes32 constant SECOND_RUNNER_UP       = keccak256(abi.encodePacked(TABLE_NAME, "secondRunnerUp"));
    bytes32 constant OTHER_BETTORS          = keccak256(abi.encodePacked(TABLE_NAME, "otherBettors"));
    bytes32 constant ENDOWNMENT             = keccak256(abi.encodePacked(TABLE_NAME, "endownment"));
    bytes32 constant LISTING_FEE            = keccak256(abi.encodePacked(TABLE_NAME, "listingFee"));
    bytes32 constant TICKET_FEE             = keccak256(abi.encodePacked(TABLE_NAME, "ticketFee"));
    bytes32 constant BETTING_FEE            = keccak256(abi.encodePacked(TABLE_NAME, "bettingFee"));
    bytes32 constant KITTIE_REDEMPTION_FEE  = keccak256(abi.encodePacked(TABLE_NAME, "kittieRedemptionFee"));
    // bytes32 constant KITTIE_EXPIRY          = keccak256(abi.encodePacked(TABLE_NAME, "kittieExpiry"));
    bytes32 constant MINIMUM_CONTRIBUTORS   = keccak256(abi.encodePacked(TABLE_NAME, "minimumContributors"));
    bytes32 constant FINALIZE_REWARDS       = keccak256(abi.encodePacked(TABLE_NAME, "finalizeRewards"));

}
