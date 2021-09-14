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
 * "My childlike creativity, purity, and honesty is honestly being crowded by these grown thoughts"
 */

contract CryptomediaFactory is ICryptomediaFactory {
    // ======== Storage ========
    address public logic;
    address public bondingCurve;

    // Mapping from contentHash to bool
    mapping(bytes32 => bool) private _contentHashes;

    bytes32 public constant DEPLOY_WITH_SIG_TYPEHASH =
        keccak256(
            "DeployWithSig(bytes32 contentHash,bytes32 metadataHash,uint256 feePct,uint256 nonce,uint256 deadline)"
        );

    // Mapping from address to deploy with sig nonce
    mapping(address => uint256) public deployWithSigNonces;

    // ======== Events ========
    event CryptomediaDeployed(
        address indexed contractAddress,
        address indexed creator,
        uint256 feePct
    );

    // ======== Constructor ========
    constructor(address _bondingCurve) {
        bondingCurve = _bondingCurve;
        logic = address(new Cryptomedia(bondingCurve));
    }

    /**
     * @dev Calculates EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     * @notice to ensure multiple dapps don't use two identical structs for message signing
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
        // require creator fee to be percentage < 100
        require(feePct <= 10**18, "Fee: percentage above 100");
        // store unique content hash
        _contentHashes[data.contentHash] = true;
        bytes32 domainSeparator = _calculateDomainSeparator();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        DEPLOY_WITH_SIG_TYPEHASH,
                        data.contentHash,
                        data.metadataHash,
                        feePct,
                        deployWithSigNonces[creator]++,
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
