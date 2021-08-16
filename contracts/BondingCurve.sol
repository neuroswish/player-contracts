// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./Power.sol";
import "./libraries/YieldMath.sol";

contract BondingCurve is Power {
    uint32 private constant maxRatio = 1000000;
    uint256 private constant slopeFactor = 100000;

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
    ) internal returns (uint256) {
        // initialize supply if supply = 0
        if (_supply == 0 || _poolBalance == 0) {
            init();
            (uint256 temp, uint256 precision) = powerInitial(
                (_price * slopeFactor),
                _reserveRatio,
                maxRatio,
                _reserveRatio,
                maxRatio
            );
            return (temp >> precision);
        } else {
            (uint256 result, uint8 precision) = power(
                (_price + _poolBalance),
                _poolBalance,
                _reserveRatio,
                maxRatio
            );
            return (((_supply * result) >> precision) - _supply);
        }
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
}
