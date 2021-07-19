// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./ContinuousToken.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title Market
 * @author neuroswish
 *
 * Create Cryptomedia
 *
 * "It won't feel right 'till I feel like Phil Knight"
 */

contract CryptomediaLogic is ContinuousToken, ReentrancyGuardUpgradeable {
    // ======== constants ========
    // TODO fix this to reflect etherscan oracle
    uint256 internal maxGasPrice = 20 gwei;

    // ======== immutable storage ========
    string public mediaURI;

    // ======== mutable attributes ========
    uint256 public poolBalance;
    uint256 public supply;
    mapping(address => uint256) public tokenBalance;
    mapping(address => address) public PNFT;

    /**
     * @notice Implement a ceiling on valid gas prices to mitigate front-running
     */
    modifier gasThrottle() {
        require(tx.gasprice <= maxGasPrice);
        _;
    }

    //TODO finish
    modifier isPlayer() {
        _;
    }

    // ======== Initialize new market ========
    function initialize(string memory _mediaURI) public initializer {
        ContinuousToken.initialize();
    }

    // ======== Token functions ========
    function mintStartingSupply() external payable returns (bool) {
        require(msg.value >= 0);
        uint256 tokensToMint = calculatePurchaseReturnInitial(msg.value);
        supply += tokensToMint;
        poolBalance += msg.value;
        tokenBalance[msg.sender] += tokensToMint;
        return true;
    }

    function buy() external payable gasThrottle returns (bool) {
        require(msg.value > 0);
        uint256 tokensToMint = calculatePurchaseReturn(
            poolBalance,
            supply,
            msg.value
        );
        supply += tokensToMint;
        tokenBalance[msg.sender] += tokensToMint;
        poolBalance += msg.value;
        return true;
    }

    function sell(uint256 _tokens)
        external
        payable
        gasThrottle
        nonReentrant
        returns (bool)
    {
        require(
            _tokens > 0 && tokenBalance[msg.sender] >= _tokens,
            "Insufficient token balance"
        );
        uint256 ethAmount = calculateSaleReturn(poolBalance, supply, _tokens);
        require(
            address(this).balance >= ethAmount,
            "Insufficient ETH to redeem"
        );
        sendValue(payable(msg.sender), ethAmount);
        poolBalance -= ethAmount;
        supply -= _tokens;
        tokenBalance[msg.sender] -= _tokens;
        return true;
    }

    // ======== Manage Profile NFTs ========

    // ============ Utility ============

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}