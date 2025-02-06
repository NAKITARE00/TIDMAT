module backend::MyCoin {
    use std::signer;
    use std::string;
    use aptos_framework::coin;
    use aptos_framework::account;

    struct MyCoin has key {}

    struct MyCapabilities has key {
        burn_cap: coin::BurnCapability<MyCoin>,
        freeze_cap: coin::FreezeCapability<MyCoin>,
        mint_cap: coin::MintCapability<MyCoin>,
    }

    const ENO_CAPABILITIES: u64 = 1;
    const EINVALID_BALANCE: u64 = 2;

    fun init_module(account: &signer) {
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<MyCoin>(
            account,
            string::utf8(b"MyCoin"),
            string::utf8(b"MYCN"),
            8, // decimals
            true, // monitor_supply
        );

        move_to(account, MyCapabilities {
            burn_cap,
            freeze_cap,
            mint_cap,
        });
    }

    public entry fun mint(
        account: &signer,
        amount: u64,
        to: address,
    ) acquires MyCapabilities {
        let account_addr = signer::address_of(account);
        let capabilities = borrow_global<MyCapabilities>(account_addr);
        
        if (!coin::is_account_registered<MyCoin>(to)) {
            coin::register<MyCoin>(account);
        };
        
        let coins = coin::mint<MyCoin>(amount, &capabilities.mint_cap);
        coin::deposit(to, coins);
    }

    public entry fun transfer(
        from: &signer,
        to: address,
        amount: u64,
    ) {
        if (!coin::is_account_registered<MyCoin>(to)) {
            coin::register<MyCoin>(from);
        };
        
        coin::transfer<MyCoin>(from, to, amount);
    }

    public entry fun burn(
        account: &signer,
        amount: u64,
    ) acquires MyCapabilities {
        let account_addr = signer::address_of(account);
        let capabilities = borrow_global<MyCapabilities>(account_addr);
        
        let coins = coin::withdraw<MyCoin>(account, amount);
        coin::burn(coins, &capabilities.burn_cap);
    }
}