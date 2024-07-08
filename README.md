# NFT Auction Smart Contract for Sui Blockchain

This repository contains a smart contract package for creating and auctioning Non-Fungible Tokens (NFTs) on the Sui blockchain. The package includes modules for NFT creation, auction management, and comprehensive testing.

## Table of Contents

1. [Overview](#overview)
2. [Project Structure](#project-structure)
3. [Prerequisites](#prerequisites)
4. [Installation](#installation)
5. [Usage](#usage)
6. [Deployment](#deployment)
7. [Testing](#testing)
8. [Contributing](#contributing)

## Overview

This smart contract package allows users to:

- Create and mint NFTs
- Transfer NFT ownership
- Create auctions for NFTs
- Place bids on auctions
- End auctions and transfer NFTs to winners
- Automatically return NFTs to sellers if no bids are placed

The contract is written in the Move language for the Sui blockchain, ensuring secure and efficient operations.

## Project Structure

The project consists of three main modules:

1. `nft.move`: Handles NFT creation, minting, and transfers.
2. `auction.move`: Manages the auction process, including creation, bidding, and completion.
3. `auction_tests.move`: Contains comprehensive tests for both the NFT and auction functionalities.

## Prerequisites

Before you begin, ensure you have the following installed:

- [Sui CLI](https://docs.sui.io/build/install)
- [Move language](https://github.com/move-language/move)
- [Git](https://git-scm.com/downloads)

## Installation

1. Clone the repository:

```
git clone https://github.com/PGOpenda/nft_auction.git
```

```
cd nft-auction-sui
```

2. Build the project:

```
sui move build
```

## Usage

#### Creating an NFT

To create an NFT, use the `mint` function in the `nft` module:
```
nft::mint(name, description, image_url)
```
One can also transfer the NFT to another if they wished with `transfer_nft` function in the same module:
```
nft::transfer_nft(nft,recipient)
```

#### Creating an Auction
To start an auction for an NFT, use the `create_auction` function in the auction module. The duration is in milliseconds:
```
auction::create_auction(nft, min_bid, duration, clock)
```

#### Placing a Bid 
To place a bid on an auction, use the `place_bid` function in the auction module:
```
auction::place_bid(auction, clock, amount, ctx)
```

#### Ending an Auction
To end an auction, use the `end_auction` function in the auction module:
```
auction::end_auction(auction, clock, ctx)
```

#### Claiming an NFT
The winner can claim their NFT using the claim_nft function in the auction module:
```
auction::claim_nft(auction, ctx)
```

## Deployment
To deploy the package to the Sui network, we use the following commands in a command line interface:

- Build the package:
  ```
  sui move build
  ```
- Deploy the package:
    ```
    sui client publish --gas-budget 10000000
    ```   
- Note the package ID from the output. You'll need this to interact with the deployed contract.
- You can also use [Suiscan](https://suiscan.xyz/mainnet/home) which provides an interface to interact with the package once deployed.

## Testing
Run the tests using the following commands in your commad line interface:
```
sui move test
```
This will execute all tests in the `nft_auction_tests` module, ensuring the correct functionality of both the NFT and auction features.

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.🙂 👍
