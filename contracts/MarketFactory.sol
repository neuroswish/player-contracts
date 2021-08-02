// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./Market.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title Market Factory
 * @author neuroswish
 *
 * Factory for deploying new market contracts
 *
 * "Listen to the kids, bro"
 */

contract MarketFactory {
    // ======== Immutable storage ========
    address public immutable logic;
    // ======== Events ========
    event marketDeployed(
        address indexed contractAddress,
        address indexed creator,
        string foundationURI
    );

    // ======== Constructor ========
    constructor() {
        logic = address(new Market(333333, 1, 100000, 10**17));
    }

    // ======== Deploy contract ========
    function createMarket(string calldata _foundationLayerURI)
        external
        payable
        returns (address market)
    {
        market = Clones.clone(logic);
        Market(market).initialize(msg.sender, _foundationLayerURI);
        emit marketDeployed(market, msg.sender, _foundationLayerURI);
    }
}
