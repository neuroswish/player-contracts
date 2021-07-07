// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import {MarketStorage} from "./MarketStorage.sol";

interface IMarketFactory {
  function logic() external returns (address);
  function parameters() external returns (string memory name, string memory symbol);
}

/**
 * @title Market
 * @author neuroswish
 *
 * Market proxy for efficiently deploying contracts
 *
 * "It won't feel right 'till I feel like Phil Knight"
 */

contract MarketProxy is MarketStorage {
  constructor() {
    logic = IMarketFactory(msg.sender).logic();
    (name, symbol) = IMarketFactory(msg.sender).parameters();
  }

  fallback() external payable
}
