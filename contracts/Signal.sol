// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
import "./interfaces/ISignal.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Signal is ISignal, Initializable, AccessControl {
    address public factory;
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant OPERATOR = keccak256("OPERATOR");

    constructor() {
        // Grant the ADMIN role to the deployer
        _setupRole(ADMIN, msg.sender);
    }

    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _operator
    ) public initializer {
        name = _name;
        symbol = _symbol;
        // Grant the OPERATOR role to specified address
        _setupRole(OPERATOR, _operator);
    }

    function _mint(address _to, uint256 _value) external {
        require(
            hasRole(ADMIN, msg.sender) || hasRole(OPERATOR, msg.sender),
            "NOT AUTHORIZED"
        );
        totalSupply = totalSupply + _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        emit Transfer(address(0), _to, _value);
    }

    function _burn(address _from, uint256 _value) external {
        require(
            hasRole(ADMIN, msg.sender) || hasRole(OPERATOR, msg.sender),
            "NOT AUTHORIZED"
        );
        balanceOf[_from] = balanceOf[_from] - _value;
        totalSupply = totalSupply - _value;
        emit Transfer(_from, address(0), _value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        _transfer(from, to, value);
        return true;
    }
}
