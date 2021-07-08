// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./MarketLogicBeacon.sol";
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
    // ======== Structs ========
    struct Parameters {
        string name;
        string symbol;
    }

    // ======== Immutable storage ========
    // address for the logic contract
    address immutable logic;

    // ======== Mutable storage ========
    // Parameters public parameters;

    // ======== Constructor ========
    // the constructor deploys an initial version that will act as a template
    constructor() {
        logic = address(new MarketLogic());
    }

    bytes4 private constant initialize =
        bytes4(
            keccak256("initialize(string memory _name, string memory _symbol)")
        );

    // ======== Deploy contract ========
    function createMarket(string calldata _name, string calldata _symbol)
        external
        returns (address)
    {
        // parameters = Parameters({name: _name, symbol: _symbol});
        BeaconProxy proxy = new BeaconProxy(
            address(UpgradeableBeacon(logic)),
            abi.encodeWithSelector(initialize, _name, _symbol)
        );
        // delete parameters;
        return address(proxy);
    }
}
