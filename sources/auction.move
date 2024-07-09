//Module that will assist in auctioning off NFTs.
module nft_auction::auction {

    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use nft_auction::nft::NFT; //Our module for creating NFTs.
    use sui::clock::{Self, Clock};
    use sui::event;

    //Definition of the auction struct
    public struct Auction has key  {
        id: UID,
        nft: Option<NFT>, // NFT being auctioned  
        seller: address, // The person who instantiates the auction 
        highest_bidder: address, // Address of the highest bidder
        current_bid: u64, // Current highest bid
        min_bid: u64, // minimum bid acceptable
        end_time: u64, // Auction end time in milliseconds (ms), example 500000ms
        coin_balance: Balance<SUI>, //It will assist us in transferring the payment to the seller
        auction_ended: bool, //indicates whether the auction is still ongoing
    }

    //Auction Created Event
    public struct AuctionCreated has copy, drop {
        auction_id: ID,
        nft_id: ID,
        seller: address,
        start_price: u64,
        end_time: u64,
    }

    //Bid Placed Event
    public struct BidPlaced has copy, drop {
        auction_id: ID,
        bidder: address,
        amount: u64,
    } 

    //Auction Ended Event
    public struct AuctionEnded has copy, drop {
        auction_id: ID,
        winner: address,
        final_price: u64,
    }

    //NFT Claimed Event
    public struct NFTClaimed has copy, drop {
        auction_id: ID,
        winner: address,
    }

    // Auction Ended with No Bids Event
    public struct AuctionEndedNoBids has copy, drop {
        auction_id: ID,
        seller: address,
    }

    //Error constants
    const ETimeExpired: u64 = 0;

    const EBidTooLow: u64 = 1;

    const EAuctionNotEnded: u64 = 2;

    const ENotWinner: u64 = 3;

    const ENFTAlreadyClaimed: u64 = 4;

    const EZeroDuration: u64 = 5;

    const EZeroBid: u64 = 6;

    //Function for creating a new auction
    public entry fun create_auction(nft: NFT, min_bid: u64, duration: u64, clock: &Clock, ctx: &mut TxContext) {

        // Check if min_bid is zero
        assert!(min_bid > 0, EZeroBid);
        // Check if duration is zero
        assert!(duration > 0, EZeroDuration);
        
        //Add the duration to get the end time for the auction. 
        let end_time = clock::timestamp_ms(clock) + duration;
        //Varibale to store the transaction context
        let seller = ctx.sender();
        //The id for the nft
        let nft_id = object::id(&nft);

        let auction = Auction {
            id: object::new(ctx),
            nft: std::option::some(nft),
            seller,
            highest_bidder: seller,
            current_bid: min_bid,
            min_bid,
            end_time,
            coin_balance: balance::zero(),
            auction_ended: false,
        };

        event::emit( AuctionCreated {
            auction_id: object::id(&auction),
            nft_id,
            seller,
            start_price: min_bid,
            end_time,
            
        });       

        //Share the auction object
        transfer::share_object(auction);   
    }
    
    //Function for placing a new bid
    public entry fun place_bid(auction: &mut Auction, clock: &Clock, coin: &mut Coin<SUI>, ctx: &mut TxContext){
        
        // Check if the bid amount is zero
        assert!(coin.value() > 0 && coin.value() > auction.current_bid , EZeroBid);
        //Get the time of what it is currently
        let now = clock::timestamp_ms(clock);
        assert!(now < auction.end_time, ETimeExpired);

        //Get the address of the bidder
        let bidder = ctx.sender();

        //Refund process of the previous highest bidder
        if (auction.highest_bidder != auction.seller) {
            transfer::public_transfer(
                coin::split(amount, auction.current_bid, ctx),
                auction.highest_bidder
            );
        };

        //Set the current bid and highest bidder
        auction.current_bid = bid_amount;
        auction.highest_bidder = bidder;

        //We update the balance in the auction by calling this function
        update_balance_with_coin(auction,bid_amount,amount,ctx);

        event::emit(BidPlaced {
            auction_id: object::id(auction),
            bidder,
            amount: bid_amount,
        });

    }

    //Function that will assist us with updating the coin balance of the auction struct
    public fun update_balance_with_coin(auction: &mut Auction, new_amount: u64, payment: &mut Coin<SUI>,ctx: &mut TxContext) {
        
        //Extract the value of the balance
        let current_balance = &mut auction.coin_balance;
        let current_value = balance::value(current_balance);
        
        // Need to add to the balance
        let to_add = new_amount - current_value;
        let added = coin::split(payment, to_add, ctx);
        balance::join(current_balance, coin::into_balance(added));
        
    }


    //Function for ending the auction
    public entry fun end_auction(auction: &mut Auction, clock: &Clock, ctx: &mut TxContext) {

        //Get the time currently
        let now = clock::timestamp_ms(clock);
        assert!(now >= auction.end_time, EAuctionNotEnded);

        // Mark the auction as ended
        auction.auction_ended = true;

        // Check if there were any bids
        if (auction.highest_bidder == auction.seller) {
            // No bids were placed, return the NFT to the seller
            let nft = std::option::extract(&mut auction.nft);
            transfer::public_transfer(nft, auction.seller);

            event::emit(AuctionEndedNoBids {
                auction_id: object::id(auction),
                seller: auction.seller,
            });

        } else {
            // There was a winning bid
            let winner = auction.highest_bidder;
            let final_price = auction.current_bid;

            // Transfer funds to the seller
            transfer::public_transfer(
                coin::take(&mut auction.coin_balance, final_price, ctx),
                auction.seller
            );

            event::emit(AuctionEnded {
                auction_id: object::id(auction),
                winner,
                final_price,
            });
        }

    }

    //Function for the winner to claim their NFT
    public fun claim_nft(auction: &mut Auction, ctx: &mut TxContext) {
        
        // Ensure the auction has ended
        assert!(auction.auction_ended, EAuctionNotEnded); 
        // Ensure the claimer is the winner
        assert!(ctx.sender() == auction.highest_bidder, ENotWinner); 
        // Ensure the NFT is still in the auction (i.e., it wasn't returned to the seller)
        assert!(std::option::is_some(&auction.nft), ENFTAlreadyClaimed);

        let winner = auction.highest_bidder;
        
        // Extract the NFT from the auction struct
        let nft = std::option::extract(&mut auction.nft);

        // Transfer the NFT to the winner
        transfer::public_transfer(nft, winner);

        event::emit(NFTClaimed {
            auction_id: object::id(auction),
            winner,
        });

    } 

    //Getter functions for testing
    public fun current_bid(auction: &Auction): u64 {
    auction.current_bid
    }

    public fun highest_bidder(auction: &Auction): address {
        auction.highest_bidder
    }

    public fun auction_ended(auction: &Auction): bool {
        auction.auction_ended
    }

}
