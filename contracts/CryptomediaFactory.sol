// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./Cryptomedia.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title Cryptomedia Factory
 * @author neuroswish
 *
 * Factory for deploying new cryptomedia
 *
 * "Good morning, look at the valedictorian. Scared of the future while I hop in the DeLorean"
 */

contract CryptomediaFactory {
    // ======== Immutable storage ========
    address public immutable logic;
    address public immutable bondingCurve;
    // ======== Events ========
    event CryptomediaDeployed(
        address indexed contractAddress,
        address indexed creator,
        string cryptomediaName
    );

    // ======== Constructor ========
    constructor(address _bondingCurve) {
        bondingCurve = _bondingCurve;
        logic = address(new Cryptomedia());
    }

    // ======== Deploy contract ========
    function createCryptomedia(
        string calldata _name,
        string[] calldata _choices
    ) external returns (address cryptomedia) {
        cryptomedia = Clones.clone(logic);
        Cryptomedia(cryptomedia).initialize(_name, bondingCurve, _choices);
        emit CryptomediaDeployed(cryptomedia, msg.sender, _name);
    }
}
