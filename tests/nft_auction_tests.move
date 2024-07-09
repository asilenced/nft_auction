#[test_only]
module nft_auction::auction_tests {
    use sui::test_scenario::{Self};
    use sui::clock::{Self};
    use sui::coin::{Self};
    use sui::sui::SUI;
    use std::string;

    use nft_auction::auction::{Self, Auction, AuctionCap};
    use nft_auction::nft::{Self, NFT};
  

    // Test helper function to create a test NFT
    // fun create_test_nft(scenario: &mut Scenario) {
    //     let ctx = test_scenario::ctx(scenario);
    //     nft::mint(string::utf8(b"Test NFT"),string::utf8(b"A test NFT for auction"),string::utf8(b"https://example.com/test-nft.jpg"),ctx)
    // }


    //THESE TESTS ARE FOR THE NFT MODULE THAT ALLOWS PEOPLE TO CREATE AND TRANSFER NFTS TO OTHER ADDRESSES

    #[test]
    fun test_mint_nft() {
        let mut scenario = test_scenario::begin(@0x1);
        let ctx = test_scenario::ctx(&mut scenario);
        
        // Mint an NFT
        nft::mint(string::utf8(b"Test NFT"), string::utf8(b"A test NFT"),string::utf8(b"https://example.com/test-nft.jpg"),ctx);
        
        // Check if the NFT was created and transferred to the sender
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let nft = test_scenario::take_from_sender<NFT>(&scenario);
            assert!(nft::name(&nft) == string::utf8(b"Test NFT"), 0);
            assert!(nft::description(&nft) == string::utf8(b"A test NFT"), 1);
            assert!(nft::image_url(&nft) == string::utf8(b"https://example.com/test-nft.jpg"), 2);
            test_scenario::return_to_sender(&scenario, nft);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_transfer_nft() {
        let mut scenario = test_scenario::begin(@0x1);
        let ctx = test_scenario::ctx(&mut scenario);
        
        // Mint an NFT
        nft::mint(string::utf8(b"Transfer Test NFT"), string::utf8(b"An NFT to transfer"), string::utf8(b"https://example.com/test-nft.jpg"),ctx);
        
        // Transfer the NFT to another address
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let nft_test = test_scenario::take_from_sender<NFT>(&scenario);
            transfer::public_transfer(nft_test, @0x2);
        };
        
        // Check if the NFT was transferred to the new address
        test_scenario::next_tx(&mut scenario, @0x2);
        {
            let nft_test = test_scenario::take_from_address<NFT>(&scenario, @0x2);
            assert!(nft::name(&nft_test) == string::utf8(b"Transfer Test NFT"), 2);
            test_scenario::return_to_address(@0x2, nft_test);
        };
        
        test_scenario::end(scenario);
    }
    

    // THESE ARE THE TESTS FOR THE AUCTION MODULE THAT ALLOWS CREATION OF NEW AUCTIONS, BIDDING ON A NFT, ENDING AN AUCTION AND CLAIMING AN NFT

    #[test]
    fun test_create_auction() {
        let mut scenario = test_scenario::begin(@0x1);
        let ctx = test_scenario::ctx(&mut scenario);
        let clock = clock::create_for_testing(ctx);

        // Mint an NFT
        nft::mint(string::utf8(b"Transfer Test NFT"), string::utf8(b"An NFT to transfer"), string::utf8(b"https://example.com/test-nft.jpg"),ctx);

        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let nft = test_scenario::take_from_sender<NFT>(&scenario);
            auction::create_auction(nft, 100, 3600000, &clock, test_scenario::ctx(&mut scenario));
        };

        // Check if the auction was created
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            assert!(test_scenario::has_most_recent_shared<Auction>(), 0);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_place_bid() {
        let mut scenario = test_scenario::begin(@0x1);
        let ctx = test_scenario::ctx(&mut scenario);
        let clock = clock::create_for_testing(ctx);
        
        // Create an NFT and start an auction
        nft::mint(string::utf8(b"Transfer Test NFT"), string::utf8(b"An NFT to transfer"), string::utf8(b"https://example.com/test-nft.jpg"),ctx);
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let nft = test_scenario::take_from_sender<NFT>(&scenario);
            auction::create_auction(nft, 100, 3600000, &clock, test_scenario::ctx(&mut scenario));
        };

        // Place a bid
        test_scenario::next_tx(&mut scenario, @0x2);
        {
            let mut auction = test_scenario::take_shared<Auction>(&scenario);
            let mut coin = coin::mint_for_testing<SUI>(200, test_scenario::ctx(&mut scenario));
            auction::place_bid(&mut auction, &clock, &mut coin, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(auction);
            coin::burn_for_testing(coin);
        };

        // Check if the bid was placed
        test_scenario::next_tx(&mut scenario, @0x2);
        {
            let auction = test_scenario::take_shared<Auction>(&scenario);
            assert!(auction::current_bid(&auction) == 200, 0);
            assert!(auction::highest_bidder(&auction) == @0x2, 1);
            test_scenario::return_shared(auction);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_end_auction_no_bids() {
        let mut scenario = test_scenario::begin(@0x1);
        let ctx = test_scenario::ctx(&mut scenario);
        let mut clock = clock::create_for_testing(ctx);
        
        // Create an NFT and start an auction
        nft::mint(string::utf8(b"Test NFT"), string::utf8(b"An NFT for auction"), string::utf8(b"https://example.com/test-nft.jpg"), ctx);
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let nft = test_scenario::take_from_sender<NFT>(&scenario);
            auction::create_auction(nft, 100, 3600000, &clock, test_scenario::ctx(&mut scenario));
        };

        // End the auction without any bids
        clock::increment_for_testing(&mut clock, 3600001);
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let mut auction = test_scenario::take_shared<Auction>(&scenario);
            let cap = test_scenario::take_from_sender<AuctionCap>(&scenario);

            auction::end_auction(&cap, &mut auction, &clock, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(auction);
            test_scenario::return_to_sender(&scenario, cap);
        };

        // Check if the NFT was returned to the seller
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            assert!(test_scenario::has_most_recent_for_sender<NFT>(&scenario), 0);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_end_auction() {
        let mut scenario = test_scenario::begin(@0x1);
        let ctx = test_scenario::ctx(&mut scenario);
        let mut clock = clock::create_for_testing(ctx);
        
        // Create an NFT and start an auction
        nft::mint(string::utf8(b"Transfer Test NFT"), string::utf8(b"An NFT to transfer"), string::utf8(b"https://example.com/test-nft.jpg"),ctx);
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let nft = test_scenario::take_from_sender<NFT>(&scenario); 
            auction::create_auction(nft, 100, 3600000, &clock, test_scenario::ctx(&mut scenario));
        };
        

        // Place a bid
        test_scenario::next_tx(&mut scenario, @0x2);
        {
            let mut auction = test_scenario::take_shared<Auction>(&scenario);
            let mut coin = coin::mint_for_testing<SUI>(200, test_scenario::ctx(&mut scenario));
            auction::place_bid(&mut auction, &clock, &mut coin, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(auction);
            coin::burn_for_testing(coin);
        };

        // End the auction
        clock::increment_for_testing(&mut clock, 3600001);
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let mut auction = test_scenario::take_shared<Auction>(&scenario);
            let cap = test_scenario::take_from_sender<AuctionCap>(&scenario);

            auction::end_auction(&cap, &mut auction, &clock, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(auction);
            test_scenario::return_to_sender(&scenario, cap);
        };

        // Check if the auction ended
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let auction = test_scenario::take_shared<Auction>(&scenario);
            assert!(auction::auction_ended(&auction), 0);
            test_scenario::return_shared(auction);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_claim_nft() {
        let mut scenario = test_scenario::begin(@0x1);
        let ctx = test_scenario::ctx(&mut scenario);
        let mut clock = clock::create_for_testing(ctx);
        
        // Create an NFT and start an auction
        nft::mint(string::utf8(b"Transfer Test NFT"), string::utf8(b"An NFT to transfer"), string::utf8(b"https://example.com/test-nft.jpg"),ctx);
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let nft = test_scenario::take_from_sender<NFT>(&scenario);
            auction::create_auction(nft, 100, 3600000, &clock, test_scenario::ctx(&mut scenario));
        };

        // Place a bid
        test_scenario::next_tx(&mut scenario, @0x2);
        {
            let mut auction = test_scenario::take_shared<Auction>(&scenario);
            let mut coin = coin::mint_for_testing<SUI>(200, test_scenario::ctx(&mut scenario));
            auction::place_bid(&mut auction, &clock, &mut coin, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(auction);
            coin::burn_for_testing(coin);
        };

        // End the auction
        clock::increment_for_testing(&mut clock, 3600001);
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let mut auction = test_scenario::take_shared<Auction>(&scenario);
            let cap = test_scenario::take_from_sender<AuctionCap>(&scenario);

            auction::end_auction(&cap, &mut auction, &clock, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(auction);
            test_scenario::return_to_sender(&scenario, cap);
        };

        // Claim the NFT
        test_scenario::next_tx(&mut scenario, @0x2);
        {
            let mut auction = test_scenario::take_shared<Auction>(&scenario);
            auction::claim_nft(&mut auction, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(auction);
        };

        // Check if the NFT was transferred to the winner
        test_scenario::next_tx(&mut scenario, @0x2);
        {
            assert!(test_scenario::has_most_recent_for_sender<NFT>(&scenario), 0);
        };

        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }
}