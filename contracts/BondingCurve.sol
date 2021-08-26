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
     * @dev given a token supply, reserve balance, weight and a deposit amount (in the reserve token),
     * calculates the target amount for a given conversion (in the main token)
     *
     * Formula:
     * return = _supply * ((1 + _amount / _reserveBalance) ^ (_reserveWeight / 1000000) - 1)
     *
     * @param _supply          liquid token supply
     * @param _poolBalance  reserve balance
     * @param _reserveRatio   reserve weight, represented in ppm (1-1000000)
     * @param _price          amount of reserve tokens to get the target amount for
     *
     * @return target
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
     * @dev given a token supply, reserve balance, weight and a sell amount (in the main token),
     * calculates the target amount for a given conversion (in the reserve token)
     *
     * Formula:
     * return = _reserveBalance * (1 - (1 - _amount / _supply) ^ (1000000 / _reserveWeight))
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
     * @dev given a price, reserve ratio, and slope value,
     * calculates the token return when initializing the bonding curve supply
     *
     * Formula:
     * return = (_price / (_reserveRatio * _slope)) ** _reserveRatio
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
}
