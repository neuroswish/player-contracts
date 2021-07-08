// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import {MarketProxy} from "./MarketProxy.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

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
    address public immutable logic;

    // ======== Mutable storage ========
    Parameters public parameters;

    // ======== Constructor ========
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
    }
}
