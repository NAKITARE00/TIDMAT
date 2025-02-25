#[test_only]
module tidmat::stake_tests {
    use std::signer;
    use aptos_framework::timestamp;
    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_framework::object;
    use aptos_framework::primary_fungible_store;
    use std::string;
    use std::option;
    use tidmat::stake;

    const STAKER: address = @0x123;
    const RECIPIENT: address = @0x456;

    const INITIAL_STAKE: u64 = 5000;
    const TRANSFER_AMOUNT: u64 = 1000;

    fun setup_fa(aptos_framework: &signer, admin: &signer, staker: &signer, recipient: &signer) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        timestamp::update_global_time_for_test_secs(1000);

        let owner_addr = signer::address_of(admin);
        let staker_amount = 10000;
        let recipient_amount = 500;

        let fa_obj_constructor_ref = &object::create_sticky_object(owner_addr);

        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            fa_obj_constructor_ref,
            option::none(),
            string::utf8(b"Test FA"),
            string::utf8(b"TF"),
            8,
            string::utf8(b"url"),
            string::utf8(b"url"),
        );

        primary_fungible_store::mint(
            &fungible_asset::generate_mint_ref(fa_obj_constructor_ref),
            signer::address_of(staker),
            staker_amount
        );

        primary_fungible_store::mint(
            &fungible_asset::generate_mint_ref(fa_obj_constructor_ref),
            signer::address_of(recipient),
            recipient_amount
        );

        stake::init_module_for_test_with_fa(aptos_framework, admin, object::object_from_constructor_ref<Metadata>(fa_obj_constructor_ref));
    }

    #[test(aptos_framework = @std, admin = @tidmat, staker = @0x123, recipient = @0x456)]
    fun test_create_stake_pool_success(aptos_framework: &signer, admin: &signer, staker: &signer, recipient: &signer) {
        setup_fa(aptos_framework, admin, staker, recipient);

        let stake_pool = stake::create_stake_pool(staker, INITIAL_STAKE);
        
        let balance = stake::get_pool_bal(&stake_pool);
        
        assert!(balance == INITIAL_STAKE, 1);
    }

    #[test(aptos_framework = @std, admin = @tidmat, staker = @0x123, recipient = @0x456)]
    #[expected_failure(abort_code = stake::EINVALID_AMOUNT)]
    fun test_create_stake_pool_zero_amount(aptos_framework: &signer, admin: &signer, staker: &signer, recipient: &signer) {
        setup_fa(aptos_framework, admin, staker, recipient);

        stake::create_stake_pool(staker, 0);
    }

    #[test(aptos_framework = @std, admin = @tidmat, staker = @0x123, recipient = @0x456)]
    #[expected_failure(abort_code = stake::ENOT_ENOUGH_BAL)]
    fun test_create_stake_pool_insufficient_funds(aptos_framework: &signer, admin: &signer, staker: &signer, recipient: &signer) {
        setup_fa(aptos_framework, admin, staker, recipient);

        // Try to stake more than the staker has
        stake::create_stake_pool(staker, 20000);
    }

    #[test(aptos_framework = @std, admin = @tidmat, staker = @0x123, recipient = @0x456)]
    fun test_transfer_from_pool_success(aptos_framework: &signer, admin: &signer, staker: &signer, recipient: &signer) {
        setup_fa(aptos_framework, admin, staker, recipient);

        let stake_pool = stake::create_stake_pool(staker, INITIAL_STAKE);
        let initial_balance = stake::get_pool_bal(&stake_pool);
        
        assert!(initial_balance == INITIAL_STAKE, 1);

        // Transfer from pool to recipient
        let recipient_addr = signer::address_of(recipient);
        stake::transfer_from_pool(&mut stake_pool, recipient_addr, TRANSFER_AMOUNT);
        
        // Check updated pool balance
        let updated_balance = stake::get_pool_bal(&stake_pool);
        assert!(updated_balance == INITIAL_STAKE - TRANSFER_AMOUNT, 2);
    }

    #[test(aptos_framework = @std, admin = @tidmat, staker = @0x123, recipient = @0x456)]
    #[expected_failure(abort_code = stake::EINSUFFICIENT_FUNDS)]
    fun test_transfer_from_pool_insufficient_funds(aptos_framework: &signer, admin: &signer, staker: &signer, recipient: &signer) {
        setup_fa(aptos_framework, admin, staker, recipient);

        let stake_pool = stake::create_stake_pool(staker, INITIAL_STAKE);
        
        // Try to transfer more than available in the pool
        let recipient_addr = signer::address_of(recipient);
        stake::transfer_from_pool(&mut stake_pool, recipient_addr, INITIAL_STAKE + 1000);
    }

    #[test(aptos_framework = @std, admin = @tidmat, staker = @0x123, recipient = @0x456)]
    fun test_get_escrow_pool(aptos_framework: &signer, admin: &signer, staker: &signer, recipient: &signer) {
        setup_fa(aptos_framework, admin, staker, recipient);

        let stake_pool = stake::create_stake_pool(staker, INITIAL_STAKE);
        
        let escrow_pool = stake::get_escrow_pool(&stake_pool);
        assert!(object::is_object(object::object_address(&escrow_pool)), 1);
    }

    #[test(aptos_framework = @std, admin = @tidmat, staker = @0x123, recipient = @0x456)]
    fun test_multiple_transfers(aptos_framework: &signer, admin: &signer, staker: &signer, recipient: &signer) {
        setup_fa(aptos_framework, admin, staker, recipient);

        let stake_pool = stake::create_stake_pool(staker, INITIAL_STAKE);
        let recipient_addr = signer::address_of(recipient);
        
        // First transfer
        stake::transfer_from_pool(&mut stake_pool, recipient_addr, 1000);
        assert!(stake::get_pool_bal(&stake_pool) == INITIAL_STAKE - 1000, 1);
        
        // Second transfer
        stake::transfer_from_pool(&mut stake_pool, recipient_addr, 500);
        assert!(stake::get_pool_bal(&stake_pool) == INITIAL_STAKE - 1500, 2);
        
        // Third transfer
        stake::transfer_from_pool(&mut stake_pool, recipient_addr, 200);
        assert!(stake::get_pool_bal(&stake_pool) == INITIAL_STAKE - 1700, 3);
    }

    #[test(aptos_framework = @std, admin = @tidmat, staker = @0x123, recipient = @0x456)]
    fun test_create_multiple_stake_pools(aptos_framework: &signer, admin: &signer, staker: &signer, recipient: &signer) {
        setup_fa(aptos_framework, admin, staker, recipient);

        // First pool
        let stake_pool1 = stake::create_stake_pool(staker, 1000);
        assert!(stake::get_pool_bal(&stake_pool1) == 1000, 1);
        
        // Second pool
        let stake_pool2 = stake::create_stake_pool(staker, 2000);
        assert!(stake::get_pool_bal(&stake_pool2) == 2000, 2);
        
        // Verify the first pool is still intact
        assert!(stake::get_pool_bal(&stake_pool1) == 1000, 3);
    }
}
