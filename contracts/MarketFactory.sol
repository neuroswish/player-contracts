// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./Market.sol";
import "./Signal.sol";
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
    address public immutable signalToken;
    // ======== Events ========
    event MarketDeployed(
        address indexed contractAddress,
        address indexed creator,
        string marketName,
        string marketSymbol,
        address bondingCurve,
        address signalToken
    );

    // ======== Constructor ========
    constructor(address _bondingCurve) {
        bondingCurve = _bondingCurve;
        logic = address(new Market());
        signalToken = address(new Signal());
    }

    // ======== Deploy contract ========
    function createMarket(string calldata _name, string calldata _symbol)
        external
        returns (address market, address signal)
    {
        market = Clones.clone(logic);
        signal = Clones.clone(signalToken);
        Market(market).initialize(
            _name,
            _symbol,
            bondingCurve,
            address(signal)
        );
        Signal(signal).initialize(
            "VERSE V1",
            string(abi.encodePacked("VERSE-V1", "-", _symbol)),
            address(market)
        );
        emit MarketDeployed(
            market,
            msg.sender,
            _name,
            _symbol,
            bondingCurve,
            address(signal)
        );
    }
}
