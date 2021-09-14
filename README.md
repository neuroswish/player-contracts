# Introduction

Player is a protocol for continuous NFTs, currently the V0 is a WIP and I'm open-sourcing the code I have thus far to enable community collaboration on refining and testing the contracts. 

**These contracts have not been robustly tested or audited thus far. DO NOT use them on mainnet or with real funds, as they could be lost forever. You have been warned!**



# How does it work?

The protocol is used to deploy `Cryptomedia` contracts. Each `Cryptomedia` contract is deployed by a creator through the `CryptomediaFactory`. The `CryptomediaFactory` takes in the creator's address, hashed contentURI and metadataURI data, and the reward fee the creator specifies for each transaction. The `CryptomediaFactory` then deploys a new `Cryptomedia` contract with the creator's signature. Each `Cryptomedia` contract is initialized with this information, and also contains the `bondingCurve` address for the bonding curve logic used to facilitate continuous token transactions.

Upon deployment, anyone can call the `mint(uint256 _minTokensReturned)` function to mint an NFT from the contract. The caller must specify an amount of continuous tokens which represents the NFT's fractional value with respect to the bonding curve. The caller then sends the appropriate amount of ETH associated with the current exchange rate for the specified number of continuous tokens, and is minted an NFT with a unique `tokenId` in return. 

The NFT holder can then call the `burn(uint256 _tokenId)` function at any time to transfer his NFT to the contract, which subsequently burns the NFT and sends the holder ETH in proportion to the exchange rate & number of continuous tokens the user bought during the minting step. 

# Usage

    # install dependencies
    npm install
    # compile
    npx hardhat compile

# Stuff to do

These contracts still need to be tested and there is likely to be bugs that need to be fixed. I'll probably start a Discord server if there's enough interest from people to jam on this together, build out a V1, and eventually an interface. In the meantime, DM me on Twitter at @neuroswish if you're interested in working on this together. 
