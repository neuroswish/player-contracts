// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface ISignal {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function getName() external view returns (string memory);

    function getSymbol() external view returns (string memory);

    function getTotalSupply() external view returns (uint256);

    function getBalanceOf(address _owner) external view returns (uint256);

    function getAllowance(address _owner, address _spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}
