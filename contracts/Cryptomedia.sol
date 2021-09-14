// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
import "./BondingCurve.sol";
import "./ERC721Burnable.sol";
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
    mapping(uint256 => uint256) public tokenBalance; // mapping of an address to that user's continuous token balance for this contract

    // ======== Creator params ========
    address public creator; // contract creator
    MediaData public data; // NFT data
    uint256 feePct; // creator fee percentage
    uint256 feeBase; // fee base

    // ======== Player params ========
    // Mapping from token id to holder address
    mapping(uint256 => address) public tokenHolders;

    // Mapping from token id to sha256 hash of content
    mapping(uint256 => bytes32) public tokenContentHashes;

    // Mapping from token id to sha256 hash of metadata
    mapping(uint256 => bytes32) public tokenMetadataHashes;

    // Mapping from token id to metadataURI
    mapping(uint256 => string) private _tokenMetadataURIs;

    // token ID tracker
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

    // ======== Modifiers ========

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
     * @dev constructor sets bonding curve address
     */
    constructor(address _bondingCurve) ERC721("Player", "PLAYER") {
        bondingCurve = _bondingCurve;
    }

    /**
     * @dev initialize function called by factory when deploying new proxy; sets creator address, media data, and creator fee percentage
     */
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

    /* **************
     * External Functions
     * **************
     */

    /**
     * @notice Mint new NFT for buyer
     * @dev requires buyer to specify minimum number of continuous tokens they want to receive representing share of contract
     */
    function mint(uint256 _minTokens) external payable nonReentrant {
        // generate new NFT token ID
        uint256 tokenId = _tokenIdTracker.current();
        // buy continuous tokens
        buy(tokenId, msg.value, _minTokens);
        // mint NFT for caller
        _safeMint(msg.sender, tokenId);
        _tokenIdTracker.increment();
        _setTokenContentHash(tokenId, data.contentHash);
        _setTokenMetadataHash(tokenId, data.metadataHash);
        _setTokenMetadataURI(tokenId, data.metadataURI);
        _setTokenURI(tokenId, data.tokenURI);
        tokenHolders[tokenId] = msg.sender;
    }

    /**
     * @notice Burn NFT and receive instant liquidity in the form of ETH by exchanging continuous tokens through bonding curve.
     * @dev Only callable if the media owner is also the creator.
     */
    function burn(uint256 _tokenId, uint256 _minETHReturned)
        external
        nonReentrant
        onlyExistingToken(_tokenId)
        onlyApprovedOrOwner(msg.sender, _tokenId)
    {
        address owner = ownerOf(_tokenId);

        require(
            tokenHolders[_tokenId] == owner,
            "Media: owner is not creator of media"
        );
        sell(_tokenId, _minETHReturned);
        _burn(_tokenId);
    }

    /**
     * @notice Buy continuous tokens with ETH
     * @dev Emits a Buy event upon success
     */
    function buy(
        uint256 _tokenId,
        uint256 _price,
        uint256 _minTokensReturned
    ) private {
        require(msg.value == _price && msg.value > 0, "INVALID PRICE");
        require(_minTokensReturned > 0, "INVALID SLIPPAGE");
        // calculate creator fee;
        uint256 fee = (_price * feePct) / feeBase;
        // update price used to buy tokens
        _price -= fee;
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
        // send fee to creator
        sendValue(creator, fee);
        emit Buy(
            msg.sender,
            poolBalance,
            continuousTotalSupply,
            tokensReturned,
            _price
        );
    }

    /* **************
     * Private Functions
     * **************
     */

    /**
     * @notice Sell continuous tokens for ETH
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
        // burn continuous tokens
        uint256 sellAmt = tokenBalance[_tokenId];
        _continuousBurn(_tokenId, sellAmt);
        poolBalance -= ethReturned;
        // send corresponding ETH from selling continuous tokens to caller
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

    /* **************
     * Internal Helper Functions
     * **************
     */

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
        super._transfer(from, to, tokenId);
    }

    /* **************
     * Utility Functions
     * **************
     */

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
