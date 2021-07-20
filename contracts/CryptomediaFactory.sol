// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./CryptomediaLogic.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

/**
 * @title Cryptomedia Factory
 * @author neuroswish
 *
 * Factory for deploying new markets
 *
 * "Listen to the kids, bro"
 */

contract CryptomediaFactory {
    // ======== Immutable storage ========
    address public immutable logic;

    // ======== Constructor ========
    constructor() {
        logic = address(new CryptomediaLogic());
    }

    // ======== Deploy contract ========
    function createCryptomedia(string calldata _mediaURI)
        external
        returns (address cryptomediaProxy)
    {
        bytes memory _initializationCalldata = abi.encodeWithSignature(
            "initialize(string,address)",
            _mediaURI,
            msg.sender
        );

        cryptomediaProxy = address(
            new BeaconProxy(
                address(new UpgradeableBeacon(logic)),
                _initializationCalldata
            )
        );
    }
}
