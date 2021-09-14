// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./Cryptomedia.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/ICryptomediaFactory.sol";
import "./interfaces/ICryptomedia.sol";

/**
 * @title Cryptomedia Factory
 * @author neuroswish
 *
 * Factory for deploying new cryptomedia
 *
 * "Good morning, look at the valedictorian. Scared of the future while I hop in the DeLorean"
 */

contract CryptomediaFactory is ICryptomediaFactory {
    // ======== Immutable storage ========
    address public immutable logic;
    address public immutable bondingCurve;

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
    // ======== Events ========
    event CryptomediaDeployed(
        address indexed contractAddress,
        address indexed creator,
        uint256 feePct
    );

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

    // ======== Constructor ========
    constructor(address _bondingCurve) {
        bondingCurve = _bondingCurve;
        logic = address(new Cryptomedia(bondingCurve));
    }

    /**
     * @dev Calculates EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function _calculateDomainSeparator() internal view returns (bytes32) {
        uint256 chainID;
        /* solium-disable-next-line */
        assembly {
            chainID := chainid()
        }

        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes("Player")),
                    keccak256(bytes("1")),
                    chainID,
                    address(this)
                )
            );
    }

    // ======== Deploy contract ========
    function createCryptomediaWithSig(
        address creator,
        ICryptomedia.MediaData memory data,
        uint256 feePct,
        EIP712Signature memory sig
    ) external returns (address cryptomedia) {
        require(
            bytes(data.tokenURI).length != 0,
            "Media: specified uri must be non-empty"
        );
        require(
            bytes(data.metadataURI).length != 0,
            "Media: specified uri must be non-empty"
        );
        require(data.contentHash != 0, "Media: content hash must be non-zero");
        require(
            _contentHashes[data.contentHash] == false,
            "Media: a token has already been created with this content hash"
        );
        require(
            data.metadataHash != 0,
            "Media: metadata hash must be non-zero"
        );
        require(
            sig.deadline == 0 || sig.deadline >= block.timestamp,
            "Media: mintWithSig expired"
        );
        bytes32 domainSeparator = _calculateDomainSeparator();

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        MINT_WITH_SIG_TYPEHASH,
                        data.contentHash,
                        data.metadataHash,
                        //bidShares.creator.value,
                        mintWithSigNonces[creator]++,
                        sig.deadline
                    )
                )
            )
        );

        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);

        require(
            recoveredAddress != address(0) && creator == recoveredAddress,
            "Media: Signature invalid"
        );

        cryptomedia = Clones.clone(logic);
        Cryptomedia(cryptomedia).initialize(recoveredAddress, data, feePct);
        emit CryptomediaDeployed(cryptomedia, msg.sender, feePct);
    }
}
