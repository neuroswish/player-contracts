// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./BondingCurve.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title Market
 * @author neuroswish
 *
 * Build markets for the creation and curation of information
 *
 * "It won't feel right 'till I feel like Phil Knight"
 */

contract MarketLogic is BondingCurve, ReentrancyGuardUpgradeable {
    // ======== constants ========
    // TODO fix this to reflect etherscan oracle
    uint256 internal maxGasPrice = 20 gwei;

    // ======== immutable storage ========
    string public name;
    string public symbol;

    // ======== mutable attributes ========
    uint256 public poolBalance;
    uint256 public supply;
    mapping(address => uint256) public tokenBalance;

    /**
     * @notice Implement a ceiling on valid gas prices to mitigate front-running
     */
    modifier gasThrottle() {
        require(tx.gasprice <= maxGasPrice);
        _;
    }

    function initialize(string memory _name, string memory _symbol)
        public
        initializer
    {
        name = _name;
        symbol = _symbol;
        __ReentrancyGuard_init();
    }

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
