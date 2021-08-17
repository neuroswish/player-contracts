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
    address public immutable bondingCurve;
    // ======== Events ========
    event marketDeployed(
        address indexed contractAddress,
        address indexed creator,
        string marketName,
        string marketTokenSymbol
    );

    // ======== Constructor ========
    constructor(address _bondingCurve) {
        bondingCurve = _bondingCurve;
        logic = address(new Market());
    }

    // ======== Deploy contract ========
    function createMarket(string calldata _name, string calldata _symbol)
        external
        returns (address market)
    {
        market = Clones.clone(logic);
        Market(market).initialize(_name, _symbol, bondingCurve);
        emit marketDeployed(market, msg.sender, _name, _symbol);
    }
}
