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

    bytes32 constant FUTURE_GAME_TIME       = keccak256(abi.encodePacked(TABLE_NAME, "futureGameTime"));
    bytes32 constant GAME_PRESTART          = keccak256(abi.encodePacked(TABLE_NAME, "gamePrestart"));
    bytes32 constant GAME_DURATION          = keccak256(abi.encodePacked(TABLE_NAME, "gameDuration"));
    bytes32 constant KITTIE_HELL_EXPIRATION = keccak256(abi.encodePacked(TABLE_NAME, "kittieHellExpiration"));
    bytes32 constant HONEY_POT_EXPIRATION   = keccak256(abi.encodePacked(TABLE_NAME, "honeypotExpiration"));
    bytes32 constant SCHEDULE_TIME_LIMITS   = keccak256(abi.encodePacked(TABLE_NAME, "scheduleTimeLimits"));
    bytes32 constant TOKENS_PER_GAME        = keccak256(abi.encodePacked(TABLE_NAME, "tokensPerGame"));
    bytes32 constant ETH_PER_GAME           = keccak256(abi.encodePacked(TABLE_NAME, "ethPerGame"));
    bytes32 constant DAILY_GAME_AVAILABILITY = keccak256(abi.encodePacked(TABLE_NAME, "dailyGameAvailability"));
    bytes32 constant GAME_TIMES             = keccak256(abi.encodePacked(TABLE_NAME, "gameTimes"));
    bytes32 constant GAME_LIMIT             = keccak256(abi.encodePacked(TABLE_NAME, "gameLimit"));
    bytes32 constant GAMES_RATE_LIMIT_FEE   = keccak256(abi.encodePacked(TABLE_NAME, "gamesRateLimitFee"));
    bytes32 constant WINNING_KITTIE         = keccak256(abi.encodePacked(TABLE_NAME, "winningKittie"));
    bytes32 constant TOP_BETTOR             = keccak256(abi.encodePacked(TABLE_NAME, "topBettor"));
    bytes32 constant SECOND_RUNNER_UP       = keccak256(abi.encodePacked(TABLE_NAME, "secondRunnerUp"));
    bytes32 constant OTHER_BETTORS          = keccak256(abi.encodePacked(TABLE_NAME, "otherBettors"));
    bytes32 constant ENDOWNMENT             = keccak256(abi.encodePacked(TABLE_NAME, "endownment"));
    bytes32 constant TICKET_FEE             = keccak256(abi.encodePacked(TABLE_NAME, "ticketFee"));
    bytes32 constant BETTING_FEE            = keccak256(abi.encodePacked(TABLE_NAME, "bettingFee"));
    bytes32 constant KITTIE_REDEMPTION_FEE  = keccak256(abi.encodePacked(TABLE_NAME, "kittieRedemptionFee"));
    bytes32 constant KITTIE_EXPIRY          = keccak256(abi.encodePacked(TABLE_NAME, "kittieExpiry"));
    bytes32 constant HONEY_POT_DURATION     = keccak256(abi.encodePacked(TABLE_NAME, "honeyPotDuration"));
    bytes32 constant MINIMUM_CONTRIBUTORS   = keccak256(abi.encodePacked(TABLE_NAME, "minimumContributors"));

}
