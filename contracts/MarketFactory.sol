// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./Market.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title Market Factory
 * @author neuroswish
 *
 * Factory for deploying new markets
 *
 * "Good morning, look at the valedictorian. Scared of the future while I hop in the DeLorean"
 */

contract MarketFactory {
    // ======== Immutable storage ========
    address public immutable logic;
    address public immutable bondingCurve;
    // ======== Events ========
    event MarketDeployed(
        address indexed contractAddress,
        address indexed creator,
        string marketName
    );

    // ======== Constructor ========
    constructor(address _bondingCurve) {
        bondingCurve = _bondingCurve;
        logic = address(new Market());
    }

    // ======== Deploy contract ========
    function createMarket(string calldata _name)
        external
        returns (address market)
    {
        market = Clones.clone(logic);
        Market(market).initialize(_name, bondingCurve);
        emit MarketDeployed(market, msg.sender, _name);
    }
}
