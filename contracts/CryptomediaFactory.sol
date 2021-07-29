// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./Cryptomedia.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title Cryptomedia Factory
 * @author neuroswish
 *
 * Factory for deploying new cryptomedia contracts
 *
 * "Listen to the kids, bro"
 */

contract CryptomediaFactory {
    // ======== Immutable storage ========
    address public immutable logic;
    // ======== Events ========
    event cryptomediaDeployed(
        address indexed contractAddress,
        address indexed creator,
        string foundationURI
    );

    // ======== Constructor ========
    constructor() {
        logic = address(new Cryptomedia(333333, 1, 100000, 10**17));
    }

    // ======== Deploy contract ========
    function createCryptomedia(string calldata _foundationLayerURI)
        external
        payable
        returns (address cryptomedia)
    {
        cryptomedia = Clones.clone(logic);
        Cryptomedia(cryptomedia).initialize(_foundationLayerURI, msg.sender);
        emit cryptomediaDeployed(cryptomedia, msg.sender, _foundationLayerURI);
    }
}
