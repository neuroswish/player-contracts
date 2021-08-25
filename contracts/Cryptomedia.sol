// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
import "./BondingCurve.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IBondingCurve.sol";

/**
 * @title Cryptomedia
 * @author neuroswish
 *
 * Multiplayer cryptomedia
 *
 * "All of you Mario, it's all a game"
 */

contract Cryptomedia is ReentrancyGuardUpgradeable {
    // ======== Interface addresses ========
    address public bondingCurve;

    // ======== Continuous token params ========
    string public name; // cryptomedia name
    uint32 public reserveRatio; // reserve ratio in ppm
    uint32 public ppm; // ppm units
    uint256 public poolBalance; // ETH balance in contract pool
    uint256 public totalSupply; // total supply of tokens in circulation
    mapping(address => uint256) public balanceOf; // mapping of an address to that user's total token balance for this contract

    // ======== Player params ========
    mapping(address => bool) public created; // mapping of an address to bool representing whether address has already added a layer
    mapping(address => mapping(address => bool)) public isCuratingLayer; // mapping of an address to mapping representing whether address is curating a layer

    // ======== Layer params ========
    struct Layer {
        address creator; // layer creator
        string URI; // layer content URI
    }
    mapping(address => Layer) public addressToLayer; // mapping from an address to the layer the address has created

    // ======== Events ========
    event Buy(
        address indexed buyer,
        uint256 poolBalance,
        uint256 totalSupply,
        uint256 tokens,
        uint256 price
    );
    event Sell(
        address indexed seller,
        uint256 poolBalance,
        uint256 totalSupply,
        uint256 tokens,
        uint256 eth
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event LayerAdded(address indexed creator, string contentURI);
    event LayerRemoved(address indexed creator);
    event CurationAdded(address indexed curator, address indexed layerCreator);
    event CurationRemoved(
        address indexed curator,
        address indexed layerCreator
    );

    // ======== Modifiers ========
    /**
     * @notice Check to see if address holds tokens
     */
    modifier holder(address user) {
        require(balanceOf[user] > 0, "MUST HOLD TOKENS");
        _;
    }

    // ======== Initializer for new market proxy ========
    /**
     * @notice Check to see if address holds tokens
     * @dev Sets reserveRatio, ppm, name, and bondingCurve address
     */
    function initialize(string calldata _name, address _bondingCurve)
        public
        payable
        initializer
    {
        reserveRatio = 333333;
        ppm = 1000000;
        name = _name;
        bondingCurve = _bondingCurve;
        __ReentrancyGuard_init();
    }

    // ======== Functions ========

    /**
     * @notice Buy market tokens with ETH
     * @dev Emits a Buy event upon success; callable by anyone
     */
    function buy(uint256 _price, uint256 _minTokensReturned) public payable {
        require(msg.value == _price && msg.value > 0, "INVALID PRICE");
        require(_minTokensReturned > 0, "INVALID SLIPPAGE");
        // calculate tokens returned
        uint256 tokensReturned;
        if (totalSupply == 0) {
            tokensReturned = IBondingCurve(bondingCurve)
                .calculateInitializationReturn(_price, reserveRatio);
            require(tokensReturned >= _minTokensReturned, "SLIPPAGE");
        } else {
            tokensReturned = IBondingCurve(bondingCurve)
                .calculatePurchaseReturn(
                    totalSupply,
                    poolBalance,
                    reserveRatio,
                    _price
                );
            require(tokensReturned >= _minTokensReturned, "SLIPPAGE");
        }
        // mint tokens
        _mint(msg.sender, tokensReturned);
        poolBalance += _price;
        emit Buy(msg.sender, poolBalance, totalSupply, tokensReturned, _price);
    }

    /**
     * @notice Sell market tokens for ETH
     * @dev Emits a Sell event upon success; callable by token holders
     */
    function sell(uint256 _tokens, uint256 _minETHReturned)
        public
        holder(msg.sender)
        nonReentrant
    {
        require(
            _tokens > 0 && _tokens <= balanceOf[msg.sender],
            "INVALID TOKEN AMT"
        );
        require(poolBalance > 0, "PB<0");
        require(_minETHReturned > 0, "INVALID SLIPPAGE");
        // calculate ETH returned
        uint256 ethReturned = IBondingCurve(bondingCurve).calculateSaleReturn(
            totalSupply,
            poolBalance,
            reserveRatio,
            _tokens
        );
        require(ethReturned >= _minETHReturned, "SLIPPAGE");
        // burn tokens
        _burn(msg.sender, _tokens);
        poolBalance -= ethReturned;
        sendValue(payable(msg.sender), ethReturned);
        emit Sell(msg.sender, poolBalance, totalSupply, _tokens, ethReturned);
    }

    /**
     * @notice Add a cryptomedia layer
     * @dev Emits a LayerAdded event upon success; callable by token holders
     */
    function addLayer(string memory _URI) public holder(msg.sender) {
        require(!created[msg.sender], "ALREADY CREATED");
        Layer memory layer;
        layer.URI = _URI;
        layer.creator = msg.sender;
        created[msg.sender] = true;
        addressToLayer[msg.sender] = layer;
        emit LayerAdded(msg.sender, _URI);
    }

    /**
     * @notice Remove a cryptomedia layer
     * @dev Emits a LayerRemoved event upon success; callable by token holders
     */

    function removeLayer() public holder(msg.sender) {
        require(created[msg.sender], "HAVE NOT CREATED");
        Layer memory layer;
        addressToLayer[msg.sender] = layer;
        created[msg.sender] = false;
        emit LayerRemoved(msg.sender);
    }

    /**
     * @notice Curate a cryptomedia by specifying the layer creator
     * @dev Emits a Curated event upon success; callable by token holders
     */
    function curate(address _creator) public holder(msg.sender) {
        require(!isCuratingLayer[msg.sender][_creator], "ALREADY CURATED");
        isCuratingLayer[msg.sender][_creator] = true;
        emit CurationAdded(msg.sender, _creator);
    }

    /**
     * @notice Remove a curation from a cryptomedia layer by specifying the layer creator
     * @dev Emits a Removed event upon success; callable by token holders
     */
    function removeCuration(address _creator) public holder(msg.sender) {
        require(isCuratingLayer[msg.sender][_creator], "HAVE NOT CURATED");
        isCuratingLayer[msg.sender][_creator] = false;
        emit CurationRemoved(msg.sender, _creator);
    }

    // ============ Utility ============

    /**
     * @notice Send ETH in a safe manner
     * @dev Prevents reentrancy, emits a Transfer event upon success
     */
    function sendValue(address recipient, uint256 amount)
        internal
        nonReentrant
    {
        require(address(this).balance >= amount, "INVALID AMT");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = payable(recipient).call{value: amount}("REVERTED");
        emit Transfer(address(this), msg.sender, amount);
        require(success);
    }

    /**
     * @notice Mints tokens
     * @dev Emits a Transfer event upon success
     */
    function _mint(address _to, uint256 _value) private {
        totalSupply = totalSupply + _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        emit Transfer(address(0), _to, _value);
    }

    /**
     * @notice Burns tokens
     * @dev Emits a Transfer event upon success
     */
    function _burn(address _from, uint256 _value) private {
        balanceOf[_from] = balanceOf[_from] - _value;
        totalSupply = totalSupply - _value;
        emit Transfer(_from, address(0), _value);
    }
}
