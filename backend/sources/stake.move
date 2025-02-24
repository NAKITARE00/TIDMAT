module tidmat::stake {
    use std::signer;
    use std::error;
    use aptos_framework::timestamp;
    use aptos_framework::object::{Self, ExtendRef, Object};
    use aptos_framework::fungible_asset::{Self, Metadata, FungibleStore};
    use aptos_framework::primary_fungible_store;

    const EINSUFFICIENT_FUNDS: u64 = 1;
    const EUNAUTHORIZED: u64 = 2;
    const ESTAKE_NOT_FOUND: u64 = 3;
    const EINVALID_AMOUNT: u64 = 4;
    const EAMOUNT_ZERO: u64 = 5;
    const ENOT_ENOUGH_BAL: u64 = 6;

    struct StakePool has key, store, drop {
	fa_metadata_object: Object<Metadata>, // Fungible asset stakers are staking rewards in
	stake_store: Object<FungibleStore>, // Fungible store to hold rewards
        total_staked: u64, // Total staked in contract
	available_bal: u64,
        owner: address, // Owner of the pool
	controller: StoreController // To act on behalf of owner for interacting with store
    }

    struct StoreController has key, store, drop {
	extend_ref: ExtendRef
    }

    struct FungibleAssetMetadata has key, store {
        fa_metadata_object: Object<Metadata>
    }

    fun init_module(admin: &signer) {
        let fa_metadata = object::address_to_object<Metadata>(@fa_metadata_addr);
        init_module_internal(admin, fa_metadata);
    }

    fun init_module_internal(admin: &signer, fa_metadata_object: Object<Metadata>) {
        move_to(admin, FungibleAssetMetadata {
           fa_metadata_object
        });
    }


    public fun create_creator_store_ctlr(owner: &signer): StoreController {
	let owner_addr = signer::address_of(owner);
	let controller_ref = object::create_object(owner_addr);
	let extend_ref = object::generate_extend_ref(&controller_ref);
	
	let store_controller = StoreController {
	    extend_ref
	};

	store_controller
    }

    public fun create_stake_pool(
   	owner: &signer,
	initial_stake: u64
    ): StakePool acquires FungibleAssetMetadata {
        assert!(initial_stake > 0, error::invalid_argument(EINSUFFICIENT_FUNDS));

	let owner_addr = signer::address_of(owner);
	let fa = borrow_global<FungibleAssetMetadata>(@tidmat);

	let ctlr = create_creator_store_ctlr(owner);
	let store_signer = &generate_store_signer(&ctlr.extend_ref);
	let stake_store = fungible_asset::create_store(
	    &object::create_object(signer::address_of(store_signer)), 
	    fa.fa_metadata_object
	);

	assert!(primary_fungible_store::balance(owner_addr, fa.fa_metadata_object) >= initial_stake, ENOT_ENOUGH_BAL);

	fungible_asset::transfer(
	    owner,
	    primary_fungible_store::primary_store(owner_addr, fa.fa_metadata_object),
	    stake_store,
	    initial_stake
	);

 	let pool = StakePool {
	    fa_metadata_object: fa.fa_metadata_object,
	    stake_store,
	    total_staked: initial_stake,
	    available_bal: initial_stake,
	    owner: owner_addr,
	    controller: ctlr
	};

	pool
    }

    public fun transfer_from_pool(pool: &mut StakePool, recipient: address, amount: u64) acquires FungibleAssetMetadata {
	assert!(pool.available_bal >= amount, EINSUFFICIENT_FUNDS);

	let fa = borrow_global<FungibleAssetMetadata>(@tidmat);

	fungible_asset::transfer(
	    &generate_store_signer(&pool.controller.extend_ref),
	    pool.stake_store,
	    primary_fungible_store::primary_store(recipient, fa.fa_metadata_object),
	    amount
	);
	pool.total_staked = pool.total_staked - amount;
	pool.available_bal = pool.available_bal - amount;
    } 


    fun generate_store_signer(extend_ref: &ExtendRef): signer {
	object::generate_signer_for_extending(extend_ref)
    }

    public fun get_pool_bal(pool: &StakePool): u64 {
	pool.available_bal
    }

    #[test_only]
    public fun init_module_for_test_with_fa(aptos_framework: &signer, sender: &signer, fa_metadata_object: Object<Metadata>) {
        timestamp::set_time_has_started_for_testing(aptos_framework);

        init_module_internal(sender, fa_metadata_object);
    }
}
