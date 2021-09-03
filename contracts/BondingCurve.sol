// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
/**
 * @title BondingCurve
 * @author neuroswish
 *
 * Bonding curve functions managing the purchase and sale of continuous tokens
 *
 * "Listen to the kids, bro"
 */

import "./Power.sol";

contract BondingCurve is Power {
    uint32 public constant maxRatio = 1000000;
    uint256 public constant slopeFactor = 100000;

    /**
     * @dev given total supply, pool balance, reserve ratio and a price, calculates the number of tokens returned
     *
     * Formula:
     * return = _supply * ((1 + _price / _poolBalance) ^ (_reserveRatio / maxRatio) - 1)
     *
     * @param _supply          liquid token supply
     * @param _poolBalance  reserve balance
     * @param _reserveRatio   reserve weight, represented in ppm (1-1000000)
     * @param _price          amount of reserve tokens to get the target amount for
     *
     * @return tokens
     */
    function calculatePurchaseReturn(
        uint256 _supply,
        uint256 _poolBalance,
        uint32 _reserveRatio,
        uint256 _price
    ) public view returns (uint256) {
        // validate input
        require(_supply > 0, "INVALID SUPPLY");
        require(_poolBalance > 0, "INVALID POOL BALANCE");
        // calculate result
        (uint256 result, uint8 precision) = power(
            (_price + _poolBalance),
            _poolBalance,
            _reserveRatio,
            maxRatio
        );
        uint256 temp = (_supply * result) >> precision;
        return (temp - _supply);
    }

    /**
     * @dev given total supply, pool balance, reserve ratio and desired number of tokens, calculates the price required
     *
     * Formula:
     * return = _poolBalance * ((1 + _tokens / _supply) ^ (maxRatio / reserveRatio) - 1)
     *
     * @param _supply          liquid token supply
     * @param _poolBalance  reserve balance
     * @param _reserveRatio   reserve weight, represented in ppm (1-1000000)
     * @param _tokens          amount of reserve tokens to get the target amount for
     *
     * @return tokens
     */
    function calculatePrice(
        uint256 _supply,
        uint256 _poolBalance,
        uint32 _reserveRatio,
        uint256 _tokens
    ) public view returns (uint256) {
        (uint256 result, uint8 precision) = power(
            (_tokens + _supply),
            _supply,
            maxRatio,
            _reserveRatio
        );
        uint256 temp = (_poolBalance * result) >> precision;
        return (temp - _poolBalance);
    }

    /**
     * @dev given total supply, pool balance, reserve ratio and a token amount, calculates the amount of ETH returned
     *
     * Formula:
     * return = _poolBalance * (1 - (1 - _price / _supply) ^ (maxRatio / _reserveRatio))
     *
     * @param _supply          liquid token supply
     * @param _poolBalance  reserve balance
     * @param _reserveRatio   reserve weight, represented in ppm (1-1000000)
     * @param _tokens          amount of liquid tokens to get the target amount for
     *
     * @return reserve token amount
     */

    function calculateSaleReturn(
        uint256 _supply,
        uint256 _poolBalance,
        uint32 _reserveRatio,
        uint256 _tokens
    ) public view returns (uint256) {
        // validate input
        require(_supply > 0, "INVALID SUPPLY");
        require(_poolBalance > 0, "INVALID SUPPLY");

        // edge case for selling entire supply
        if (_tokens == _supply) {
            return _poolBalance;
        }

        (uint256 result, uint8 precision) = power(
            _supply,
            (_supply - _tokens),
            maxRatio,
            _reserveRatio
        );
        return ((_poolBalance * result) - (_poolBalance << precision)) / result;
    }

    /**
     * @dev given a price, reserve ratio, and slope factor, calculates the number of tokens returned when initializing the bonding curve supply
     *
     * Formula:
     * return = (_price / (_reserveRatio * _slopeFactor)) ** _reserveRatio
     *
     * @param _price          liquid token supply
     * @param _reserveRatio   reserve weight, represented in ppm (1-1000000)
     *
     * @return initial token amount
     */

    function calculateInitializationReturn(uint256 _price, uint32 _reserveRatio)
        public
        view
        returns (uint256)
    {
        if (_reserveRatio == maxRatio) {
            return (_price * slopeFactor);
        }
        (uint256 temp, uint256 precision) = powerInitial(
            (_price * slopeFactor),
            _reserveRatio,
            maxRatio,
            _reserveRatio,
            maxRatio
        );
        return (temp >> precision);
    }

    /**
     * @dev given a reserve ratio and slope factor, calculates the number of price required to purchase the first token when initializing the bonding curve supply
     *
     * Formula:
     * price = (_reserveRatio * slopeFactor) / maxRatio
     *
     * @param _reserveRatio   reserve weight, represented in ppm (1-1000000)
     *
     * @return price for initial token
     */

    function calculateInitializationPrice(uint32 _reserveRatio)
        public
        pure
        returns (uint256)
    {
        if (_reserveRatio == maxRatio) {
            return (slopeFactor);
        }
        return ((_reserveRatio * slopeFactor) / maxRatio);
    }
}
