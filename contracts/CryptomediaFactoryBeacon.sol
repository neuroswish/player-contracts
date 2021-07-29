// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./Cryptomedia.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

/**
 * @title Cryptomedia Factory
 * @author neuroswish
 *
 * Factory for deploying new bios
 *
 * "Listen to the kids, bro"
 */

contract CryptomediaFactory {
    // ======== Immutable storage ========
    address public immutable logic;

    // ======== Constructor ========
    constructor() {
        logic = address(new Cryptomedia(333333, 1, 1, 100000, 10**17, 10**17));
    }

    // ======== Deploy contract ========
    function createCryptomedia() external returns (address cryptomedia) {
        bytes memory _initializationCalldata = abi.encodeWithSignature(
            "initialize(string,address)",
            msg.sender
        );

        cryptomedia = address(
            new BeaconProxy(
                address(new UpgradeableBeacon(logic)),
                _initializationCalldata
            )
        );
    }
}
