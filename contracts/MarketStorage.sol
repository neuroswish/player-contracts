// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/**
 * @title Market Storage
 * @author neuroswish
 *
 * Declare storage variables for layered cryptomedia markets
 *
 * "Four in the morning, and I'm zoning. They say I'm possessed, it's an omen"
 */

contract MarketStorage {
    // ======== Continuous token params ========
    bool public supplyInitialized;
    uint256 public totalSupply; // total supply of tokens in circulation
    uint32 public reserveRatio; // reserve ratio in ppm
    uint32 public ppm = 1000000; // ppm units
    uint256 public slopeN; // slope numerator value for initial token return computation
    uint256 public slopeD; // slope denominator value for initial token return computation
    uint256 public poolBalance; // ETH balance in contract pool
    uint256 public feePct; // 10**17
    uint256 public pctBase = 10**18;
    // ======== Player params ========
    address creator;
    uint256 creatorReward;
    address[] beneficiaries;
    mapping(address => uint256) beneficiaryIndex;
    mapping(address => bool) addressIsBeneficiary;
    mapping(address => uint256) beneficiaryRewards;
    mapping(address => uint256) totalBalance; // mapping of an address to that user's total token balance for this contract

    // ======== Layer params ========
    string public foundationURI; // URI of foundational layer
    struct Layer {
        address layerCreator; // layer creator
        string URI; // layer content URI
        uint256 stakedTokens; // total amount of tokens staked in layer
        mapping(address => uint256) amountStakedByCurator; // mapping from a curator to the amount of tokens the curator has staked
    }
    Layer[] public layers; // array of all layers
    mapping(address => uint256[]) public addressToLayerIndex; // mapping from address to layer index staked by that address
    uint256 layerIndex = 0; // initialize layerIndex (foundational layer has index of 0)
}
