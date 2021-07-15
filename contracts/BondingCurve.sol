// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./Power.sol";

contract BondingCurve is Power {
    uint32 private constant maxRatio = 1000000;

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
        require(_reserveRatio > 0 && _reserveRatio <= maxRatio);

        // edge case for 0 price amount
        if (_price == 0) {
            return 0;
        }

        // edge case for reserve ratio = 100%
        if (_reserveRatio == maxRatio) {
            return (_supply * _price) / _poolBalance;
        }

        uint256 result;
        uint8 precision;

        uint256 baseN = _price + _poolBalance;
        (result, precision) = power(
            baseN,
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
        require(
            _reserveRatio > 0 && _reserveRatio <= maxRatio,
            "INVALID RESERVE RATIO"
        );
        require(_tokens <= _supply, "INVALID TOKEN AMOUNT");

        // edge case for 0 sell amount
        if (_tokens == 0) {
            return 0;
        }

        // edge case for selling entire supply
        if (_tokens == _supply) {
            return _poolBalance;
        }

        // edge case if reserve ratio = 100%
        if (_reserveRatio == maxRatio) {
            return (_reserveRatio * _tokens) / _supply;
        }

        uint256 result;
        uint8 precision;
        uint256 baseD = _supply - _tokens;
        (result, precision) = power(_supply, baseD, maxRatio, _reserveRatio);
        uint256 quant1 = _poolBalance * result;
        uint256 quant2 = _poolBalance << precision;
        return (quant1 - quant2) / result;
    }
}
