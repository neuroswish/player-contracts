// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/**
 * @title Bonding Curve
 * @author neuroswish
 *
 * Implement bonding curves to govern the pricing of continuous tokens
 *
 * "All of you Mario, it's all a game"
 */

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";

contract BondingCurve is ChainlinkClient {
    using Chainlink for ChainlinkRequest;
}
