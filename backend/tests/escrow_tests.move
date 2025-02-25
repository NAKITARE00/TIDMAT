#[test_only]
module tidmat::escrow_tests {
    use std::signer;
    use std::vector;
    use std::string;
    use std::option;
    use aptos_framework::timestamp;
    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_framework::object;
    use aptos_framework::primary_fungible_store;
    use tidmat::stake;
    use tidmat::treasury;
    use tidmat::contribution;
    use tidmat::escrow;

    const CREATOR: address = @0x123;

    const CAMPAIGN_ID: u64 = 1;
    const TOTAL_REWARD_POOL: u64 = 10000;

    fun setup_fa(aptos_framework: &signer, admin: &signer, creator: &signer, contributor1: &signer, contributor2: &signer) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        timestamp::update_global_time_for_test_secs(1000);

        let owner_addr = signer::address_of(admin);
        let creator_amount = 20000;
        let contributor1_amount = 5000;
        let contributor2_amount = 5000;

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
            signer::address_of(creator),
            creator_amount
        );

        primary_fungible_store::mint(
            &fungible_asset::generate_mint_ref(fa_obj_constructor_ref),
            signer::address_of(contributor1),
            contributor1_amount
        );

        primary_fungible_store::mint(
            &fungible_asset::generate_mint_ref(fa_obj_constructor_ref),
            signer::address_of(contributor2),
            contributor2_amount
        );

        let fa_metadata_object = object::object_from_constructor_ref<Metadata>(fa_obj_constructor_ref);
        
        treasury::init_module_for_test_with_fa(aptos_framework, admin, fa_metadata_object);
        stake::init_module_for_test_with_fa(aptos_framework, admin, fa_metadata_object);
        contribution::init_module_for_test(aptos_framework, admin);
    }

    fun setup_contributions(contributor1: &signer, contributor2: &signer) : vector<contribution::Contribution> {
        // Create test contributions
        let contribution1 = contribution::create_contrib_for_test(
            1,
            CAMPAIGN_ID,
	    signer::address_of(contributor1),
            vector::empty<u8>(),
            contribution::get_status_accepted()
        );

        let contribution2 = contribution::create_contrib_for_test(
            2,
            CAMPAIGN_ID,
	    signer::address_of(contributor2),
            vector::empty<u8>(),
            contribution::get_status_accepted()
        );

        let contributions = vector::empty<contribution::Contribution>();
        vector::push_back(&mut contributions, contribution1);
        vector::push_back(&mut contributions, contribution2);

        contributions
    }

    #[test(aptos_framework = @std, admin = @tidmat, creator = @0x123, contributor1 = @0x456, contributor2 = @0x789)]
    fun test_create_escrow_success(aptos_framework: &signer, admin: &signer, creator: &signer, contributor1: &signer, contributor2: &signer) {
        setup_fa(aptos_framework, admin, creator, contributor1, contributor2);

        let escrow = escrow::create_escrow(creator, CAMPAIGN_ID, TOTAL_REWARD_POOL);
        
        let pool_bal = escrow::get_escrow_pool_bal(&escrow);
        assert!(pool_bal == TOTAL_REWARD_POOL, 1);
    }

    #[test(aptos_framework = @std, admin = @tidmat, creator = @0x123, contributor1 = @0x456, contributor2 = @0x789)]
    #[expected_failure(abort_code = escrow::EINSUFFICIENT_FUNDS)]
    fun test_create_escrow_zero_amount(aptos_framework: &signer, admin: &signer, creator: &signer, contributor1: &signer, contributor2: &signer) {
        setup_fa(aptos_framework, admin, creator, contributor1, contributor2);

        escrow::create_escrow(creator, CAMPAIGN_ID, 0);
    }

    #[test(aptos_framework = @std, admin = @tidmat, creator = @0x123, contributor1 = @0x456, contributor2 = @0x789)]
    fun test_refund_no_fee(aptos_framework: &signer, admin: &signer, creator: &signer, contributor1: &signer, contributor2: &signer) {
        setup_fa(aptos_framework, admin, creator, contributor1, contributor2);

        let escrow = escrow::create_escrow(creator, CAMPAIGN_ID, TOTAL_REWARD_POOL);
        
        // Initial balance check
        let initial_balance = escrow::get_escrow_pool_bal(&escrow);
        assert!(initial_balance == TOTAL_REWARD_POOL, 1);
        
        // Refund without fee
        escrow::refund(creator, &mut escrow, false);
        
        // Final balance check - should be 0 as all funds are refunded
        let final_balance = escrow::get_escrow_pool_bal(&escrow);
        assert!(final_balance == 0, 2);
    }

    #[test(aptos_framework = @std, admin = @tidmat, creator = @0x123, contributor1 = @0x456, contributor2 = @0x789)]
    fun test_refund_with_fee(aptos_framework: &signer, admin: &signer, creator: &signer, contributor1: &signer, contributor2: &signer) {
        setup_fa(aptos_framework, admin, creator, contributor1, contributor2);

        let escrow = escrow::create_escrow(creator, CAMPAIGN_ID, TOTAL_REWARD_POOL);
        
        // Initial balance check
        let initial_balance = escrow::get_escrow_pool_bal(&escrow);
        assert!(initial_balance == TOTAL_REWARD_POOL, 1);
        
        // Refund with fee (10% fee should be applied)
        escrow::refund(creator, &mut escrow, true);
        
        // Final balance check - should be 10% of initial balance
        let final_balance = escrow::get_escrow_pool_bal(&escrow);
        assert!(final_balance == TOTAL_REWARD_POOL / 10, 2);
    }

    #[test(aptos_framework = @std, admin = @tidmat, creator = @0x123, contributor1 = @0x456, contributor2 = @0x789)]
    #[expected_failure(abort_code = escrow::EUNAUTHORIZED_ACCESS)]
    fun test_refund_unauthorized(aptos_framework: &signer, admin: &signer, creator: &signer, contributor1: &signer, contributor2: &signer) {
        setup_fa(aptos_framework, admin, creator, contributor1, contributor2);

        let escrow = escrow::create_escrow(creator, CAMPAIGN_ID, TOTAL_REWARD_POOL);
        
        // Try to refund with unauthorized signer (contributor1 instead of creator)
        escrow::refund(contributor1, &mut escrow, false);
    }

    #[test(aptos_framework = @std, admin = @tidmat, creator = @0x123, contributor1 = @0x456, contributor2 = @0x789)]
    fun test_release_funds(aptos_framework: &signer, admin: &signer, creator: &signer, contributor1: &signer, contributor2: &signer) {
        setup_fa(aptos_framework, admin, creator, contributor1, contributor2);

        let escrow = escrow::create_escrow(creator, CAMPAIGN_ID, TOTAL_REWARD_POOL);
        
        // Create contributions
        let contributions = setup_contributions(contributor1, contributor2);
        
        // Initial balance check
        let initial_balance = escrow::get_escrow_pool_bal(&escrow);
        assert!(initial_balance == TOTAL_REWARD_POOL, 1);
        
        // Release funds to contributors
        escrow::release_funds(creator, &mut escrow, contributions, 2);
        
        // Final balance check
        let final_balance = escrow::get_escrow_pool_bal(&escrow);
        
        // After both contributors receive their share, remaining should be 0 or a small amount due to rounding
        assert!(final_balance == 0, 2);
    }

    #[test(aptos_framework = @std, admin = @tidmat, creator = @0x123, contributor1 = @0x456, contributor2 = @0x789)]
    #[expected_failure(abort_code = escrow::EINCOMPLETE_CAMPAIGN)]
    fun test_release_funds_no_verified_contributions(aptos_framework: &signer, admin: &signer, creator: &signer, contributor1: &signer, contributor2: &signer) {
        setup_fa(aptos_framework, admin, creator, contributor1, contributor2);

        let escrow = escrow::create_escrow(creator, CAMPAIGN_ID, TOTAL_REWARD_POOL);
        
        // Create empty contributions vector
        let contributions = vector::empty<contribution::Contribution>();
        
        // Try to release funds with 0 accepted contributions
        escrow::release_funds(creator, &mut escrow, contributions, 0);
    }

    #[test(aptos_framework = @std, admin = @tidmat, creator = @0x123, contributor1 = @0x456, contributor2 = @0x789)]
    fun test_get_escrow_pool_bal(aptos_framework: &signer, admin: &signer, creator: &signer, contributor1: &signer, contributor2: &signer) {
        setup_fa(aptos_framework, admin, creator, contributor1, contributor2);

        let escrow = escrow::create_escrow(creator, CAMPAIGN_ID, TOTAL_REWARD_POOL);
        
        let pool_bal = escrow::get_escrow_pool_bal(&escrow);
        assert!(pool_bal == TOTAL_REWARD_POOL, 1);
    }
}
