module tidmat::treasury {
    use std::signer;
    use aptos_framework::timestamp;
    use aptos_framework::object::{Self, Object};
    use aptos_framework::fungible_asset::{Self, Metadata, FungibleStore};
    use aptos_framework::primary_fungible_store;

    const INSUFFICIENT_FUNDS: u64 = 1;
    const UNAUTHORIZED: u64 = 2;
    const ETREASURY_NOT_FOUND: u64 = 3;
    const ENOT_ENOUGH_BAL: u64 = 4;
  
    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct Treasury has key {
        bal: u64,
        store: Object<fungible_asset::FungibleStore>
    }

    struct Admin has key {
        addr: address
    }

    struct FungibleAssetMetadata has key, store {
	fa_metadata_object: Object<Metadata>
    }

    // Keep `init_module` private for module initialization
    fun init_module(admin: &signer) {
        let fa_metadata = object::address_to_object<Metadata>(@fa_metadata_addr);
        init_module_internal(admin, fa_metadata);
    }

    fun init_module_internal(admin: &signer, fa_metadata_object: Object<Metadata>) {
        let admin_addr = signer::address_of(admin);
        
        move_to(admin, Admin {
            addr: admin_addr
        });
        
        let controller_ref = object::create_object(admin_addr);
        
        let store = fungible_asset::create_store(    
            &controller_ref,
            fa_metadata_object
        );    

        move_to(admin, Treasury {
            bal: fungible_asset::balance(store),
            store
        });

	move_to(admin, FungibleAssetMetadata {
	   fa_metadata_object
	});
    }

    public fun process_payment(payer: &signer, store:Object<FungibleStore>, amount: u64) acquires Treasury {  
        assert!(exists<Treasury>(@tidmat), ETREASURY_NOT_FOUND);
	assert!(fungible_asset::balance(store) >= amount, ENOT_ENOUGH_BAL);

        let treasury = borrow_global_mut<Treasury>(@tidmat);

        fungible_asset::transfer(
            payer,
            store,
            treasury.store,
            amount
        );

        treasury.bal = fungible_asset::balance(treasury.store);
    }

    public entry fun withdraw_funds(admin: &signer) acquires Admin, Treasury, FungibleAssetMetadata {
        assert_admin(admin);
        
        let treasury = borrow_global<Treasury>(@tidmat);
        let fa = borrow_global<FungibleAssetMetadata>(@tidmat);
        
        fungible_asset::transfer(
            admin,
            treasury.store,
            primary_fungible_store::primary_store(signer::address_of(admin), fa.fa_metadata_object),
            treasury.bal
        );
    }

    #[view]
    public fun get_treasury_bal(): u64 acquires Treasury {
        assert!(exists<Treasury>(@tidmat), ETREASURY_NOT_FOUND);
        let treasury = borrow_global<Treasury>(@tidmat);
        treasury.bal
    }

    public fun get_fa_metadata(): Object<Metadata> acquires FungibleAssetMetadata {
	borrow_global<FungibleAssetMetadata>(@tidmat).fa_metadata_object
    }


    public fun assert_admin(account: &signer) acquires Admin {
        let account_addr = signer::address_of(account);
        let admin = borrow_global<Admin>(@tidmat);
        assert!(account_addr == admin.addr, UNAUTHORIZED);
    }

    #[test_only]
    public fun init_module_for_test_with_fa(aptos_framework: &signer, sender: &signer, fa_metadata_object: Object<Metadata>) {
	timestamp::set_time_has_started_for_testing(aptos_framework);

	init_module_internal(sender, fa_metadata_object);
    }

}
