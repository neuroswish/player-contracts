// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import {MarketProxy} from "./MarketProxy.sol";

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
    address public immutable logic;

    // ======== Mutable storage ========
    Parameters public parameters;

    // ======== Constructor ========
    // the constructor deploys an initial version that will act as a template
    constructor(address _logic) {
        logic = _logic;
    }

    // ======== Deploy contract ========
    function createMarket(string calldata _name, string calldata _symbol)
        external
        returns (address marketProxy)
    {
        parameters = Parameters({name: _name, symbol: _symbol});

        marketProxy = address(
            new MarketProxy{salt: keccak256(abi.encode(_name, _symbol))}()
        );

        delete parameters;
        return marketProxy;
    }
}
