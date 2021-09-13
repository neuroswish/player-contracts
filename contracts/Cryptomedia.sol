// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
import "./BondingCurve.sol";
import "./PlayerERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IBondingCurve.sol";
import "./libraries/Base64.sol";

/**
 * @title Cryptomedia
 * @author neuroswish
 *
 * Multiplayer cryptomedia
 *
 * "All of you Mario, it's all a game"
 */

contract Cryptomedia is ERC721, ReentrancyGuard, Initializable {
    // ======== Interface addresses ========
    address public bondingCurve; // bonding curve interface address
    string[] public choices; // user choices

    // ======== Continuous token params ========
    //string private name; // cryptomedia name
    uint32 public reserveRatio; // reserve ratio in ppm
    uint32 public ppm; // token units
    uint256 public poolBalance; // ETH balance in contract pool
    uint256 public continuousTotalSupply; // total supply of tokens in circulation
    mapping(address => uint256) public continuousBalanceOf; // mapping of an address to that user's total token balance for this contract

    // ======== Player params ========
    mapping(address => bool) public created; // mapping of an address to bool representing whether address has created a layer

    // ======== Layer params ========
    struct Layer {
        address creator; // layer creator
        string text; // layer content URI
    }
    mapping(address => Layer) private addressToLayer; // mapping from a creator's address to the layer the address has created

    // ======== Events ========
    event Buy(
        address indexed buyer,
        uint256 poolBalance,
        uint256 continuousTotalSupply,
        uint256 tokens,
        uint256 price
    );
    event Sell(
        address indexed seller,
        uint256 poolBalance,
        uint256 continuousTotalSupply,
        uint256 tokens,
        uint256 eth
    );
    event continuousTransfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
    event LayerCreated(address indexed creator, string text);
    event LayerUpdated(address indexed creator, string newText);
    event LayerRemoved(address indexed creator);

    // ======== Modifiers ========
    /**
     * @notice Check to see if address holds tokens
     */
    modifier holder(address user) {
        require(continuousBalanceOf[user] > 0, "MUST HOLD TOKENS");
        _;
    }

    /**
     * @notice Check to see if address is a creator
     */
    modifier creator(address user) {
        require(created[user], "MUST BE CREATOR");
        _;
    }

    // ======== Initializer for new market proxy ========
    /**
     * @notice Check to see if address holds tokens
     * @dev Sets reserveRatio, ppm, name, and bondingCurve address
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _bondingCurve,
        string[] calldata _choices
    ) public initializer {
        reserveRatio = 333333;
        ppm = 1000000;
        //name = _name;
        bondingCurve = _bondingCurve;
        choices = _choices;
        ERC721.initialize(_name, _symbol);
    }

    // ======== Functions ========

    /**
     * @notice Buy market tokens with ETH
     * @dev Emits a Buy event upon success
     */
    function buy(
        address _creator,
        uint256 _price,
        uint256 _minTokensReturned
    ) private {
        require(msg.value == _price && msg.value > 0, "INVALID PRICE");
        require(_minTokensReturned > 0, "INVALID SLIPPAGE");
        // calculate tokens returned
        uint256 tokensReturned;
        if (continuousTotalSupply == 0) {
            tokensReturned = IBondingCurve(bondingCurve)
                .calculateInitializationReturn(_price, reserveRatio);
        } else {
            tokensReturned = IBondingCurve(bondingCurve)
                .calculatePurchaseReturn(
                    continuousTotalSupply,
                    poolBalance,
                    reserveRatio,
                    _price
                );
        }
        // mint tokens for buyer
        _continuousMint(_creator, tokensReturned);
        poolBalance += _price;
        emit Buy(
            msg.sender,
            poolBalance,
            continuousTotalSupply,
            tokensReturned,
            _price
        );
    }

    /**
     * @notice Sell market tokens for ETH
     * @dev Emits a Sell event upon success; callable by token holders
     */
    function sell(address _creator, uint256 _minETHReturned) private {
        require(poolBalance > 0, "PB < 0");
        require(_minETHReturned > 0, "INVALID SLIPPAGE");
        // calculate ETH returned
        uint256 ethReturned = IBondingCurve(bondingCurve).calculateSaleReturn(
            continuousTotalSupply,
            poolBalance,
            reserveRatio,
            continuousBalanceOf[_creator]
        );
        require(ethReturned >= _minETHReturned, "SLIPPAGE");
        // burn tokens
        uint256 sellAmt = continuousBalanceOf[_creator];
        _continuousBurn(_creator, sellAmt);
        poolBalance -= ethReturned;
        sendValue(_creator, ethReturned);
        emit Sell(
            _creator,
            poolBalance,
            continuousTotalSupply,
            sellAmt,
            ethReturned
        );
    }

    /**
     * @notice Add a cryptomedia layer
     * @dev Emits a LayerAdded event upon success; callable by token holders
     */
    function createLayer(uint256 _choicesIndex, uint256 _minTokensReturned)
        public
        payable
    {
        require(msg.value > 0, "INVALID PRICE");
        require(_minTokensReturned > 0, "INVALID SLIPPAGE");
        require(!created[msg.sender], "ALREADY CREATED");
        require(_choicesIndex <= choices.length, "OUT OF BOUNDS");
        //require(bytes(_text).length < 300, "INPUT TOO LARGE");
        buy(msg.sender, msg.value, _minTokensReturned);
        Layer memory layer;
        string memory text = choices[_choicesIndex];
        layer.text = text;
        layer.creator = msg.sender;
        addressToLayer[msg.sender] = layer;
        created[msg.sender] = true;
        emit LayerCreated(msg.sender, text);
    }

    /**
     * @notice Remove a cryptomedia layer
     * @dev Emits a LayerRemoved event upon success; callable by token-holding creators
     */

    function burnLayer(uint256 _minETHReturned)
        public
        holder(msg.sender)
        creator(msg.sender)
    {
        sell(msg.sender, _minETHReturned);
        Layer memory layer;
        addressToLayer[msg.sender] = layer;
        created[msg.sender] = false;
        emit LayerRemoved(msg.sender);
    }

    /**
     * @notice Return the layer information for a given address that has created or curated a layer
     * @dev Must specify user address; returns layer creator address and layer URI; reverts if address has not created or curated a layer
     */
    function tokenURI(address _user) public view returns (string memory) {
        require(created[_user], "NO MATCHING LAYERS");
        string memory layerText = addressToLayer[_user].text;
        string[2] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: black; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="white" /><text x="10" y="20" class="base">';
        parts[1] = layerText;
        string memory output = string(abi.encodePacked(parts[0], parts[1]));
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": ',
                        upper(ERC721.name()),
                        '", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        return (output);
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
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @notice Mints tokens
     * @dev Emits a Transfer event upon success
     */
    function _continuousMint(address _to, uint256 _value) private {
        continuousTotalSupply = continuousTotalSupply + _value;
        continuousBalanceOf[_to] = continuousBalanceOf[_to] + _value;
        emit continuousTransfer(address(0), _to, _value);
    }

    /**
     * @notice Burns tokens
     * @dev Emits a Transfer event upon success
     */
    function _continuousBurn(address _from, uint256 _value) private {
        continuousBalanceOf[_from] = continuousBalanceOf[_from] - _value;
        continuousTotalSupply = continuousTotalSupply - _value;
        emit continuousTransfer(_from, address(0), _value);
    }

    /**
     * Upper
     *
     * Converts all the values of a string to their corresponding upper case
     * value.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to upper case
     * @return string
     */
    function upper(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint256 i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Upper
     *
     * Convert an alphabetic character to upper case and return the original
     * value when not alphabetic
     *
     * @param _b1 The byte to be converted to upper case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a lower case otherwise returns the original value
     */
    function _upper(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    // ============ ERC-721 ============
}
