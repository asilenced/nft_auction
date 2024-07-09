//Module that creates nfts, mints them, burns them and allows transfer of ownership
module nft_auction::nft {
    
    use std::string::String;

    // The struct defining our NFT object
    public struct NFT has key, store {
        id: UID,
        name: String,
        description: String,
        image_url: String,
    }

    //Function for minting a new NFT
    public entry fun mint(name: String, description: String, image_url: String, ctx: &mut TxContext) {
        
        //Create the NFT
        let nft = NFT {
            id: object::new(ctx),
            name: name,
            description: description,
            image_url: image_url,
        };
        //Transfer the nft to the owner
        transfer::public_transfer(nft, ctx.sender());
        
    }

    //Getter functions for testing
    #[test_only]
    public fun name(nft: &NFT): &String {
        &nft.name
    }
    #[test_only]
    public fun description(nft: &NFT): &String {
        &nft.description
    }
    #[test_only]
    public fun image_url(nft: &NFT): &String {
        &nft.image_url
    }

}