// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/**
 * @title Bonding Curve
 * @author neuroswish
 *
 * Implement bonding curves governing the pricing of continuous tokens
 *
 * "All of you Mario, it's all a game"
 */

import "@chainlink/contracts/src/v0.8/dev/ChainlinkClient.sol";

contract ContinuousToken is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    uint256 reserveRatioNumerator = 1;
    uint256 reserveRatioDenominator = 3;
    uint256 reserveRatio = reserveRatioNumerator / reserveRatioDenominator;

    uint256 slopeNumerator = 1;
    uint256 slopeDenominator = 1000000;
    uint256 m = slopeNumerator / slopeDenominator;

    constructor() {
        setPublicChainlinkToken();
    }

    function calculatePurchaseReturnInitial(uint256 _price)
        public
        returns (uint256)
    {}

    function calculatePurchaseReturn(
        uint256 _poolBalance,
        uint256 _supply,
        uint256 _price
    ) public returns (uint256) {}

    function calculateSaleReturn(
        uint256 _poolBalance,
        uint256 _supply,
        uint256 _tokens
    ) public returns (uint256) {}
}
