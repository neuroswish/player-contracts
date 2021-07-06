// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

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

contract Market is BondingCurve, Ownable {
    string marketName;
    string marketSymbol;
    uint256 poolBalance;
    uint256 supply;
    mapping(address => uint256) tokenBalance;

    constructor(string memory _marketName, string memory _marketSymbol) {
        marketName = _marketName;
        marketSymbol = _marketSymbol;
    }

    uint256 public poolBalance;
    // TODO set max gas price based on Etherscan oracle
    uint256 public maxGasPrice = 20 gwei;

    /**
     * @notice Implement a ceiling on valid gas prices to mitigate front-running
     */
    modifier gasThrottle() {
        require(tx.gasprice <= maxGasPrice);
        _;
    }

    function mintStartingSupply() private payable returns (uint256) {
        require(msg.value >= 0);
        uint256 tokensToMint = calculatePurchaseReturnInitial(msg.value);
        supply = supply.add(tokensToMint);
        tokenBalance[msg.sender] = tokenBalance[msg.sender].add(tokensToMint);
        poolBalance = poolBalance.add(msg.value);
        return true;
    }

    function buy() public payable gasThrottle returns (bool) {
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

    function sell(uint256 _tokens) public payable gasThrottle returns (bool) {
        require(_tokens > 0 && tokenBalance[msg.sender] >= _tokens);
        uint256 ethAmount = calculateSaleReturn(poolBalance, supply, _tokens);
        msg.sender.transfer(ethAmount);
        poolBalance = poolBalance.sub(ethAmount);
        supply = supply.sub(_tokens);
        tokenBalance[msg.sender] = tokenBalance[msg.sender].sub(_tokens);
        return true;
    }
}
