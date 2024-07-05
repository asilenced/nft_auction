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

         //Create variable so as to send the nft to creator.
        let sender = tx_context::sender(ctx);

        //Transfer the nft to the owner
        transfer::public_transfer(nft, sender);
        
    }

    public entry fun transfer_nft(nft: NFT, recipient: address) {
        transfer::public_transfer(nft, recipient);        
    }

    // Add these accessor functions
    public fun name(nft: &NFT): &String {
        &nft.name
    }

    public fun description(nft: &NFT): &String {
        &nft.description
    }

    public fun image_url(nft: &NFT): &String {
        &nft.image_url
    }

}