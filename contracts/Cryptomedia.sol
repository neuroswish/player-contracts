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
    uint32 public ppm; // token units
    uint256 public poolBalance; // ETH balance in contract pool
    uint256 public totalSupply; // total supply of tokens in circulation
    mapping(address => uint256) public balanceOf; // mapping of an address to that user's total token balance for this contract

    // ======== Player params ========
    mapping(address => bool) public created; // mapping of an address to bool representing whether address has created a layer
    mapping(address => bool) public curated; // mapping of an address to bool representing whether address has curated a layer

    // ======== Layer params ========
    struct Layer {
        address creator; // layer creator
        string URI; // layer content URI
    }
    mapping(address => Layer) private addressToCreatedLayer; // mapping from a creator's address to the layer the address has created
    mapping(address => address) private addressToCuratedLayerAddress; // mapping from a curating address to the address of the layer's creator

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
    event LayerCreated(address indexed creator, string contentURI);
    event LayerRemoved(address indexed creator);
    event CurationAdded(address indexed curator, address indexed layerCreator);
    event CurationRemoved(
        address indexed curator,
        address indexed layerCreator
    );
    event noLongerHolder(address indexed user);

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
        require(poolBalance > 0, "PB < 0");
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
        if (balanceOf[msg.sender] == 0) {
            removeHolder(msg.sender);
        }
        poolBalance -= ethReturned;
        sendValue(payable(msg.sender), ethReturned);
        emit Sell(msg.sender, poolBalance, totalSupply, _tokens, ethReturned);
    }

    /**
     * @notice If a holder sells all tokens, remove any layer created or curation
     * @dev Emits a noLongerHolder event upon success
     */
    function removeHolder(address _holder) private {
        if (created[_holder]) {
            Layer memory layer;
            addressToCreatedLayer[_holder] = layer;
            created[_holder] = false;
            emit LayerRemoved(_holder);
        } else if (curated[_holder]) {
            address layerCreator = addressToCuratedLayerAddress[msg.sender];
            addressToCuratedLayerAddress[msg.sender] = address(0);
            curated[msg.sender] = false;
            emit CurationRemoved(msg.sender, layerCreator);
        }
        emit noLongerHolder(_holder);
    }

    /**
     * @notice Add a cryptomedia layer
     * @dev Emits a LayerAdded event upon success; callable by token holders
     */
    function createLayer(string memory _URI) public holder(msg.sender) {
        require(
            !created[msg.sender] && !curated[msg.sender],
            "ALREADY CONTRIBUTED"
        );
        Layer memory layer;
        layer.URI = _URI;
        layer.creator = msg.sender;
        addressToCreatedLayer[msg.sender] = layer;
        created[msg.sender] = true;
        emit LayerCreated(msg.sender, _URI);
    }

    /**
     * @notice Remove a cryptomedia layer
     * @dev Emits a LayerRemoved event upon success; callable by token holders
     */

    function removeCreatedLayer() public holder(msg.sender) {
        require(created[msg.sender], "NOTHING TO REMOVE");
        Layer memory layer;
        addressToCreatedLayer[msg.sender] = layer;
        created[msg.sender] = false;
        emit LayerRemoved(msg.sender);
    }

    /**
     * @notice Curate a cryptomedia by specifying the layer creator
     * @dev Emits a Curated event upon success; callable by token holders
     */
    function curateLayer(address _creator) public holder(msg.sender) {
        require(
            !created[msg.sender] && !curated[msg.sender],
            "ALREADY CONTRIBUTED"
        );
        addressToCuratedLayerAddress[msg.sender] = _creator;
        curated[msg.sender] = true;
        emit CurationAdded(msg.sender, _creator);
    }

    /**
     * @notice Remove a curation from a cryptomedia layer by specifying the layer creator
     * @dev Emits a Removed event upon success; callable by token holders
     */
    function removeCuratedLayer() public holder(msg.sender) {
        require(curated[msg.sender], "NOTHING TO REMOVE");
        address layerCreator = addressToCuratedLayerAddress[msg.sender];
        addressToCuratedLayerAddress[msg.sender] = address(0);
        curated[msg.sender] = false;
        emit CurationRemoved(msg.sender, layerCreator);
    }

    // ============ Public helper functions ============

    /**
     * @notice Return the layer information for a given address that has created or curated a layer
     * @dev Must specify user address; returns layer creator address and layer URI; reverts if address has not created or curated a layer
     */
    function getLayer(address _user)
        public
        view
        returns (address, string memory)
    {
        require(created[_user] || curated[_user], "NO MATCHING LAYERS");
        if (created[_user]) {
            return (_user, addressToCreatedLayer[_user].URI);
        } else {
            return (
                addressToCuratedLayerAddress[_user],
                addressToCreatedLayer[addressToCuratedLayerAddress[_user]].URI
            );
        }
    }

    // ============ Utility ============

    /**
     * @notice Send ETH in a safe manner
     * @dev Prevents reentrancy, emits a Transfer event upon success
     */
    function sendValue(address recipient, uint256 amount) internal {
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
