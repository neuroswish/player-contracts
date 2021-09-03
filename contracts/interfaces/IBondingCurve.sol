// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface IBondingCurve {
    function calculateInitializationReturn(uint256 _price, uint32 _reserveRatio)
        external
        view
        returns (uint256);

    function calculateInitializationPrice(uint32 _reserveRatio)
        external
        pure
        returns (uint256);

    function calculatePurchaseReturn(
        uint256 _supply,
        uint256 _poolBalance,
        uint32 _reserveRatio,
        uint256 _price
    ) external returns (uint256);

    function calculatePrice(
        uint256 _supply,
        uint256 _poolBalance,
        uint32 _reserveRatio,
        uint256 _tokens
    ) external returns (uint256);

    function calculateSaleReturn(
        uint256 _supply,
        uint256 _poolBalance,
        uint32 _reserveRatio,
        uint256 _tokens
    ) external returns (uint256);
}
