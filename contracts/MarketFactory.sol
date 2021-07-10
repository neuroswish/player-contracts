// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./MarketLogic.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

/**
 * @title Market Factory
 * @author neuroswish
 *
 * Factory for deploying new markets
 *
 * "Listen to the kids, bro"
 */

contract MarketFactory {
    // ======== Immutable storage ========
    address public immutable logic;

    // ======== Constructor ========
    constructor() {
        logic = address(new MarketLogic());
    }

    // ======== Deploy contract ========
    function createMarket(string calldata _name, string calldata _symbol)
        external
        returns (address marketProxy)
    {
        bytes memory _initializationCalldata = abi.encodeWithSignature(
            "initialize(string,string)",
            _name,
            _symbol
        );

        marketProxy = address(
            new BeaconProxy(
                address(new UpgradeableBeacon(logic)),
                _initializationCalldata
            )
        );
    }
}
