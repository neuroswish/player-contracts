// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
import "./BondingCurve.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IBondingCurve.sol";

/**
 * @title Market
 * @author neuroswish
 *
 * Multiplayer cryptomedia
 *
 * "All of you Mario, it's all a game"
 */

contract Market is ReentrancyGuardUpgradeable {
    // ======== Interface addresses ========
    address public bondingCurve;

    // ======== Continuous token params ========
    string public name; // market name
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
        address[] curators; // addresses curating this layer
    }
    Layer[] public layers; // array of all layers
    mapping(address => Layer) public addressToLayer; // mapping from an address to the layer the address has created
    mapping(address => Layer[]) public addressToCuratedLayers; // mapping from an address to layer index staked by that address

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
    event LayerAdded(address indexed creator, string contentURI);
    event LayerRemoved(address indexed creator);
    event CurationAdded(address indexed curator, address indexed layerCreator);
    event CurationRemoved(
        address indexed curator,
        address indexed layerCreator
    );

    // ERC20 Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
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
    function buy(uint256 _price, uint256 _minTokensReturned)
        public
        payable
        returns (bool)
    {
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
        _mint(msg.sender, tokensReturned);
        poolBalance += _price;
        emit Buy(msg.sender, poolBalance, totalSupply, tokensReturned, _price);
        return true;
    }

    /**
     * @notice Sell market tokens for ETH
     * @dev Emits a Sell event upon success; callable by token holders
     */
    function sell(uint256 _tokens, uint256 _minETHReturned)
        public
        holder(msg.sender)
        nonReentrant
        returns (bool)
    {
        require(
            _tokens > 0 && _tokens <= balanceOf[msg.sender],
            "INVALID TOKEN AMT"
        );
        require(poolBalance > 0, "PB<0");
        require(_minETHReturned > 0, "INVALID SLIPPAGE");
        uint256 ethReturned = IBondingCurve(bondingCurve).calculateSaleReturn(
            totalSupply,
            poolBalance,
            reserveRatio,
            _tokens
        );
        require(ethReturned >= _minETHReturned, "SLIPPAGE");
        _burn(msg.sender, _tokens);
        poolBalance -= ethReturned;
        sendValue(payable(msg.sender), ethReturned);
        emit Sell(msg.sender, poolBalance, totalSupply, _tokens, ethReturned);
        return true;
    }

    /**
     * @notice Add a layer to the information market
     * @dev Emits a LayerAdded event upon success; callable by token holders
     */
    function addLayer(string memory _URI)
        public
        holder(msg.sender)
        returns (bool)
    {
        require(!created[msg.sender], "ALREADY CREATED");
        Layer memory layer;
        layer.URI = _URI;
        layer.creator = msg.sender;
        created[msg.sender] = true;
        addressToLayer[msg.sender] = layer;
        emit LayerAdded(msg.sender, _URI);
        return true;
    }

    /**
     * @notice Remove a layer from the information market
     * @dev Emits a LayerAdded event upon success; callable by token holders
     */

    function removeLayer() public holder(msg.sender) returns (bool) {
        require(created[msg.sender], "N/A");
        Layer memory layer;
        addressToLayer[msg.sender] = layer;
        return true;
    }

    /**
     * @notice Curate a layer to the information market by specifying the layer index
     * @dev Emits a Curated event upon success; callable by token holders
     */
    function curate(address _creator) public holder(msg.sender) returns (bool) {
        if (isCuratingLayer[msg.sender][_creator]) {
            revert("CURATED");
        } else {
            addressToCuratedLayers[msg.sender].push(addressToLayer[_creator]);
            emit CurationAdded(msg.sender, _creator);
            return true;
        }
    }

    /**
     * @notice Remove a curation from a layer in the information market by specifying the layer index
     * @dev Emits a Removed event upon success; callable by token holders, will revert if holder is not currently curating the layer
     */
    function removeCuration(address _creator)
        public
        holder(msg.sender)
        returns (bool)
    {
        if (!isCuratingLayer[msg.sender][_creator]) {
            revert("NOT CURATED");
        }
        // remove caller from layer's list of curators
        uint256 curatorsLength = addressToLayer[_creator].curators.length;
        for (uint256 i; i < curatorsLength; i++) {
            if (msg.sender == addressToLayer[_creator].curators[i]) {
                addressToLayer[_creator].curators[i] = addressToLayer[_creator]
                    .curators[curatorsLength - 1];
                addressToLayer[_creator].curators.pop();
            }
        }
        isCuratingLayer[msg.sender][_creator] = false;
        emit CurationRemoved(msg.sender, _creator);
        return true;
    }

    // ============ Utility ============

    /**
     * @notice Send ETH in a safe manner
     * @dev Prevents reentrancy
     */
    function sendValue(address recipient, uint256 amount)
        internal
        nonReentrant
    {
        require(address(this).balance >= amount, "INVALID AMT");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = payable(recipient).call{value: amount}("REVERTED");
        require(success);
    }

    function _mint(address _to, uint256 _value) private {
        totalSupply = totalSupply + _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        emit Transfer(address(0), _to, _value);
    }

    function _burn(address _from, uint256 _value) private {
        balanceOf[_from] = balanceOf[_from] - _value;
        totalSupply = totalSupply - _value;
        emit Transfer(_from, address(0), _value);
    }
}
