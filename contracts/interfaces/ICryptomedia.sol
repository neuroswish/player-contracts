// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface ICryptomedia {
    struct EIP712Signature {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct MediaData {
        // A valid URI of the content represented by this token
        string tokenURI;
        // A valid URI of the metadata associated with this token
        string metadataURI;
        // A SHA256 hash of the content pointed to by tokenURI
        bytes32 contentHash;
        // A SHA256 hash of the content pointed to by metadataURI
        bytes32 metadataHash;
    }

    event TokenURIUpdated(uint256 indexed _tokenId, address owner, string _uri);
    event TokenMetadataURIUpdated(
        uint256 indexed _tokenId,
        address owner,
        string _uri
    );

    // /**
    //  * @notice Return the metadata URI for a piece of media given the token URI
    //  */
    // function tokenMetadataURI(uint256 tokenId)
    //     external
    //     view
    //     returns (string memory);

    // /**
    //  * @notice Mint new media for msg.sender.
    //  */
    // function mint(MediaData calldata _data, uint256 _minTokens)
    //     external
    //     payable;

    // /**
    //  * @notice EIP-712 mintWithSig method. Mints new media for a creator given a valid signature.
    //  */
    // function mintWithSig(
    //     address creator,
    //     MediaData calldata data,
    //     uint256 _minTokens,
    //     EIP712Signature calldata sig
    // ) external;

    // /**
    //  * @notice Revoke approval for a piece of media
    //  */
    // function revokeApproval(uint256 tokenId) external;

    // /**
    //  * @notice Update the token URI
    //  */
    // function updateTokenURI(uint256 tokenId, string calldata tokenURI) external;

    // /**
    //  * @notice Update the token metadata uri
    //  */
    // function updateTokenMetadataURI(
    //     uint256 tokenId,
    //     string calldata metadataURI
    // ) external;

    // /**
    //  * @notice EIP-712 permit method. Sets an approved spender given a valid signature.
    //  */
    // function permit(
    //     address spender,
    //     uint256 tokenId,
    //     EIP712Signature calldata sig
    // ) external;
}
