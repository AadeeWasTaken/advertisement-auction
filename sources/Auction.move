module ADAuction::auction {
    use std::signer;
    use std::error;
    use std::string::String;
    use aptos_framework::coin::{ Self, Coin };
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::account::{ Self, SignerCapability };

    const SEED: vector<u8> = vector<u8>[6, 9, 4, 2, 0];

    const EBET_SMALLER_THAN_PREVIOUS_BET: u64 = 0;

    struct AD has store {
        text: String,
        image: String,
    }

    struct Auction has key {
        ad: AD,
        last_bet: u64
    }

    struct AuctionInfo has key {
        signer_cap: SignerCapability,
    }

    fun init_module(
        sender: &signer,
        base_text: String,
        base_image: String
    ) {
        let (auction_signer, signer_cap): (signer, SignerCapability) = account::create_resource_account(sender, SEED);
        
        coin::register<AptosCoin>(&auction_signer);

        move_to<Auction>(&auction_signer, Auction {
            ad: AD {
                text: base_text,
                image: base_image
            },
            last_bet: 0
        });
        
        move_to<AuctionInfo>(sender, AuctionInfo {
            signer_cap: signer_cap,
        });
    }

    public entry fun bet(
        account: &signer,
        amount: u64,
        text: String,
        image: String
    ) acquires AuctionInfo, Auction {
        let auction_info = borrow_global<AuctionInfo>(@ADAuction);
        let auction_signer: signer = account::create_signer_with_capability(&auction_info.signer_cap);
        let auction_addr: address = signer::address_of(&auction_signer);
        let auction: &mut Auction = borrow_global_mut<Auction>(auction_addr);

        assert!(amount > auction.last_bet, error::permission_denied(EBET_SMALLER_THAN_PREVIOUS_BET));
        let coin: Coin<AptosCoin> = coin::withdraw<AptosCoin>(account, amount);
        let account_addr: address = signer::address_of(account);
        let ad: &mut AD = &mut auction.ad;

        bet_internal(account_addr, coin);
        change_ad(text, image, ad);
    }

    fun bet_internal(
        account_addr: address,
        coin: Coin<AptosCoin>
    ) {
        coin::deposit<AptosCoin>(account_addr, coin);
    }

    fun change_ad(
        text: String,
        image: String,
        ad: &mut AD
    ) {
        ad.text = text;
        ad.image = image;
    }
}