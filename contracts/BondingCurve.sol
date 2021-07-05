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

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol" as SafeMath;

contract BondingCurve is ChainlinkClient {
    using Chainlink for ChainlinkRequest;
    using SafeMath for uint256;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    uint256 reserveRatio = 1.div(3);
    uint256 m = 1.div(1000000);

    constructor() public {
        setPublicChainlinkToken();
    }

    function getInitialPrice(
        uint256 storage reserveRatio,
        uint256 storage m,
        uint256 _tokens
    ) public returns (uint256) {}

    function getInitialTokens(
        uint256 storage reserveRatio,
        uint256 storage m,
        uint256 _price
    ) public returns (uint256) {}
}
