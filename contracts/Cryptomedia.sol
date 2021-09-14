// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
import "./BondingCurve.sol";
import "./ERC721Burnable.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IBondingCurve.sol";
import "./interfaces/ICryptomedia.sol";
import "./libraries/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title Cryptomedia
 * @author neuroswish
 *
 * Infinite NFTs
 *
 * "All of you Mario, it's all a game"
 */

contract Cryptomedia is
    ICryptomedia,
    ERC721Burnable,
    ReentrancyGuard,
    Initializable
{
    using Counters for Counters.Counter;
    // ======== Interface addresses ========
    address public bondingCurve; // bonding curve interface address

    // ======== Continuous token params ========
    uint32 public reserveRatio; // reserve ratio in ppm
    uint32 public ppm; // token units
    uint256 public poolBalance; // ETH balance in contract pool
    uint256 public continuousTotalSupply; // total supply of tokens in circulation
    mapping(uint256 => uint256) public tokenBalance; // mapping of an address to that user's total token balance for this contract

    // ======== Creator params ========
    address public creator;
    MediaData public data;
    uint256 feePct;
    uint256 feeBase;
    // ======== Player params ========
    // Mapping from token id to creator address
    mapping(uint256 => address) public tokenCreators;

    // Mapping from token id to sha256 hash of content
    mapping(uint256 => bytes32) public tokenContentHashes;

    // Mapping from token id to sha256 hash of metadata
    mapping(uint256 => bytes32) public tokenMetadataHashes;

    // Mapping from token id to metadataURI
    mapping(uint256 => string) private _tokenMetadataURIs;

    // Mapping from contentHash to bool
    mapping(bytes32 => bool) private _contentHashes;

    //keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x49ecf333e5b8c95c40fdafc95c1ad136e8914a8fb55e9dc8bb01eaa83a2df9ad;

    //keccak256("MintWithSig(bytes32 contentHash,bytes32 metadataHash,uint256 creatorShare,uint256 nonce,uint256 deadline)");
    bytes32 public constant MINT_WITH_SIG_TYPEHASH =
        0x2952e482b8e2b192305f87374d7af45dc2eafafe4f50d26a0c02e90f2fdbe14b;

    // Mapping from address to token id to permit nonce
    mapping(address => mapping(uint256 => uint256)) public permitNonces;

    // Mapping from address to mint with sig nonce
    mapping(address => uint256) public mintWithSigNonces;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *     bytes4(keccak256('tokenMetadataURI(uint256)')) == 0x157c3df9
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd ^ 0x157c3df9 == 0x4e222e66
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x4e222e66;

    Counters.Counter private _tokenIdTracker;

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
    event ContinuousMint(address indexed from, uint256 tokenId, uint256 value);
    event ContinuousBurn(uint256 tokenId, address indexed to, uint256 value);
    event LayerCreated(address indexed creator, string text);
    event LayerUpdated(address indexed creator, string newText);
    event LayerRemoved(address indexed creator);

    // ======== Modifiers ========
    /**
     * @notice Check to see if address holds tokens
     */
    // modifier holder(address user) {
    //     require(continuousBalanceOf[user] > 0, "MUST HOLD TOKENS");
    //     _;
    // }

    /**
     * @notice Require that the token has not been burned and has been minted
     */
    modifier onlyExistingToken(uint256 tokenId) {
        require(_exists(tokenId), "Media: nonexistent token");
        _;
    }

    /**
     * @notice Require that the token has had a content hash set
     */
    modifier onlyTokenWithContentHash(uint256 tokenId) {
        require(
            tokenContentHashes[tokenId] != 0,
            "Media: token does not have hash of created content"
        );
        _;
    }

    /**
     * @notice Require that the token has had a metadata hash set
     */
    modifier onlyTokenWithMetadataHash(uint256 tokenId) {
        require(
            tokenMetadataHashes[tokenId] != 0,
            "Media: token does not have hash of its metadata"
        );
        _;
    }

    /**
     * @notice Ensure that the provided spender is the approved or the owner of
     * the media for the specified tokenId
     */
    modifier onlyApprovedOrOwner(address spender, uint256 tokenId) {
        require(
            _isApprovedOrOwner(spender, tokenId),
            "Media: Only approved or owner"
        );
        _;
    }

    /**
     * @notice Ensure the token has been created (even if it has been burned)
     */
    modifier onlyTokenCreated(uint256 tokenId) {
        require(
            _tokenIdTracker.current() > tokenId,
            "Media: token with that id does not exist"
        );
        _;
    }

    /**
     * @notice Ensure that the provided URI is not empty
     */
    modifier onlyValidURI(string memory uri) {
        require(
            bytes(uri).length != 0,
            "Media: specified uri must be non-empty"
        );
        _;
    }

    constructor(address _bondingCurve) ERC721("Player", "PLAYER") {
        bondingCurve = _bondingCurve;
    }

    function initialize(
        address _creator,
        MediaData memory _data,
        uint256 _feePct
    ) external initializer {
        creator = _creator;
        data = _data;
        feePct = _feePct;
        feeBase = 10**18;
    }

    // ======== Functions ========

    /**
     * @notice Buy market tokens with ETH
     * @dev Emits a Buy event upon success
     */
    function buy(
        uint256 _tokenId,
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
        _continuousMint(_tokenId, tokensReturned);
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
    function sell(uint256 _tokenId, uint256 _minETHReturned) private {
        require(poolBalance > 0, "PB < 0");
        require(_minETHReturned > 0, "INVALID SLIPPAGE");
        // calculate ETH returned
        uint256 ethReturned = IBondingCurve(bondingCurve).calculateSaleReturn(
            continuousTotalSupply,
            poolBalance,
            reserveRatio,
            tokenBalance[_tokenId]
        );
        require(ethReturned >= _minETHReturned, "SLIPPAGE");
        // burn tokens
        uint256 sellAmt = tokenBalance[_tokenId];
        _continuousBurn(_tokenId, sellAmt);
        poolBalance -= ethReturned;
        sendValue(ownerOf(_tokenId), ethReturned);
        emit Sell(
            ownerOf(_tokenId),
            poolBalance,
            continuousTotalSupply,
            sellAmt,
            ethReturned
        );
    }

    /* **************
     * View Functions
     * **************
     */

    /**
     * @notice return the URI for a particular piece of media with the specified tokenId
     * @dev This function is an override of the base OZ implementation because we
     * will return the tokenURI even if the media has been burned. In addition, this
     * protocol does not support a base URI, so relevant conditionals are removed.
     * @return the URI for a token
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        onlyTokenCreated(tokenId)
        returns (string memory)
    {
        string memory _tokenURI = _tokenURIs[tokenId];

        return _tokenURI;
    }

    /**
     * @notice Return the metadata URI for a piece of media given the token URI
     * @return the metadata URI for the token
     */
    function tokenMetadataURI(uint256 tokenId)
        external
        view
        onlyTokenCreated(tokenId)
        returns (string memory)
    {
        return _tokenMetadataURIs[tokenId];
    }

    /**
     * @notice see IMedia
     */
    function mint(uint256 _minTokens) external payable nonReentrant {
        uint256 tokenId = _tokenIdTracker.current();
        buy(tokenId, msg.value, _minTokens);
        _safeMint(msg.sender, tokenId);
        _tokenIdTracker.increment();
        _setTokenContentHash(tokenId, data.contentHash);
        _setTokenMetadataHash(tokenId, data.metadataHash);
        _setTokenMetadataURI(tokenId, data.metadataURI);
        _setTokenURI(tokenId, data.tokenURI);
        _contentHashes[data.contentHash] = true;
        tokenCreators[tokenId] = msg.sender;
        //_mintForBuyer(msg.sender, data, tokenId);
    }

    /**
     * @notice Burn a token.
     * @dev Only callable if the media owner is also the creator.
     */
    function burn(uint256 tokenId)
        public
        override
        nonReentrant
        onlyExistingToken(tokenId)
        onlyApprovedOrOwner(msg.sender, tokenId)
    {
        address owner = ownerOf(tokenId);

        require(
            tokenCreators[tokenId] == owner,
            "Media: owner is not creator of media"
        );

        _burn(tokenId);
    }

    function _setTokenContentHash(uint256 tokenId, bytes32 contentHash)
        internal
        virtual
        onlyExistingToken(tokenId)
    {
        tokenContentHashes[tokenId] = contentHash;
    }

    function _setTokenMetadataHash(uint256 tokenId, bytes32 metadataHash)
        internal
        virtual
        onlyExistingToken(tokenId)
    {
        tokenMetadataHashes[tokenId] = metadataHash;
    }

    function _setTokenMetadataURI(uint256 tokenId, string memory metadataURI)
        internal
        virtual
        onlyExistingToken(tokenId)
    {
        _tokenMetadataURIs[tokenId] = metadataURI;
    }

    /**
     * @notice Destroys `tokenId`.
     * @dev We modify the OZ _burn implementation to
     * maintain metadata and to remove the
     * previous token owner from the piece
     */
    function _burn(uint256 tokenId) internal override {
        string memory _tokenURI = _tokenURIs[tokenId];

        super._burn(tokenId);

        if (bytes(_tokenURI).length != 0) {
            _tokenURIs[tokenId] = _tokenURI;
        }

        //delete previousTokenOwners[tokenId];
    }

    /**
     * @notice transfer a token and remove the ask for it.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        //IMarket(marketContract).removeAsk(tokenId);

        super._transfer(from, to, tokenId);
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
    function _continuousMint(uint256 _tokenId, uint256 _value) private {
        continuousTotalSupply = continuousTotalSupply + _value;
        tokenBalance[_tokenId] = tokenBalance[_tokenId] + _value;
        emit ContinuousMint(address(0), _tokenId, _value);
    }

    /**
     * @notice Burns tokens
     * @dev Emits a Transfer event upon success
     */
    function _continuousBurn(uint256 _tokenId, uint256 _value) private {
        tokenBalance[_tokenId] = tokenBalance[_tokenId] - _value;
        continuousTotalSupply = continuousTotalSupply - _value;
        emit ContinuousBurn(_tokenId, address(0), _value);
    }
}
