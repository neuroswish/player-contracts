// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./MarketStorage.sol";
import "./BondingCurve.sol";
import "@openzeppelin/contracts/access/Ownable.sol" as Ownable;

/**
 * @title Market
 * @author neuroswish
 *
 * Build markets for the creation and curation of information
 *
 * "It won't feel right 'till I feel like Phil Knight"
 */

contract Market is MarketStorage, BondingCurve, Ownable {
    /**
     * @notice Implement a ceiling on valid gas prices to mitigate front-running
     */
    modifier gasThrottle() {
        require(tx.gasprice <= maxGasPrice);
        _;
    }
    /**
     * @notice Prevent re-entrant function calls
     */
    modifier noReentrancy() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    function mintStartingSupply() external payable returns (uint256) {
        require(msg.value >= 0);
        uint256 tokensToMint = calculatePurchaseReturnInitial(msg.value);
        supply = supply.add(tokensToMint);
        poolBalance = poolBalance.add(msg.value);
        tokenBalance[msg.sender] = tokenBalance[msg.sender].add(tokensToMint);
        return true;
    }

    function buy() external payable gasThrottle returns (bool) {
        require(msg.value > 0);
        uint256 tokensToMint = calculatePurchaseReturn(
            poolBalance,
            supply,
            msg.value
        );
        supply = supply.add(tokensToMint);
        tokenBalance[msg.sender] = tokenBalance[msg.sender].add(tokensToMint);
        poolBalance = poolBalance.add(msg.value);
        return true;
    }

    function sell(uint256 _tokens)
        external
        payable
        gasThrottle
        noReentrancy
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
        poolBalance = poolBalance.sub(ethAmount);
        supply = supply.sub(_tokens);
        tokenBalance[msg.sender] = tokenBalance[msg.sender].sub(_tokens);
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
