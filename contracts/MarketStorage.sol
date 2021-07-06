// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/**
 * @title Market
 * @author neuroswish
 *
 * Build markets for the creation and curation of information
 *
 * "It won't feel right 'till I feel like Phil Knight"
 */

contract MarketStorage {
    // ======== constants ========
    // TODO fix this to reflect etherscan oracle
    uint256 internal maxGas = 20 gwei;

    // ======== immutable storage ========
    string public name;
    string public symbol;

    // ======== mutable storage ========
    bool internal locked;
    uint256 public poolBalance;
    uint256 public supply;
    mapping(address => uint256) public tokenBalance;

    // ======== delegation logic ========
    address public logic;
}
