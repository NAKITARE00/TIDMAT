#[test_only]
module tidmat::subscription_tests {
    use std::signer;
    use std::string;
    use std::option;
    use aptos_framework::timestamp;
    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_framework::object;
    use aptos_framework::primary_fungible_store;
    use tidmat::subscription;
    use tidmat::treasury;

    // Test addresses
    const ADMIN: address = @tidmat;
    const USER1: address = @0x123;
    const USER2: address = @0x456;
    const USER3: address = @0x789;

    // Initial token amounts for testing
    const USER1_TOKENS: u64 = 1000;
    const USER2_TOKENS: u64 = 50;
    const USER3_TOKENS: u64 = 200;

    /// Sets up the test environment including fungible asset creation and module initialization
    fun setup_test_environment(aptos_framework: &signer, admin: &signer, user1: &signer, user2: &signer, user3: &signer) {
        // Initialize timestamp for testing
        timestamp::set_time_has_started_for_testing(aptos_framework);
        timestamp::update_global_time_for_test_secs(1000);

        // Create fungible asset for testing
        let admin_addr = signer::address_of(admin);
        let fa_obj_constructor_ref = &object::create_sticky_object(admin_addr);

        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            fa_obj_constructor_ref,
            option::none(),
            string::utf8(b"Test Token"),
            string::utf8(b"TT"),
            8,
            string::utf8(b"https://test.url"),
            string::utf8(b"https://test.url"),
        );

        // Mint tokens to users
        primary_fungible_store::mint(
            &fungible_asset::generate_mint_ref(fa_obj_constructor_ref),
            signer::address_of(user1),
            USER1_TOKENS
        );

        primary_fungible_store::mint(
            &fungible_asset::generate_mint_ref(fa_obj_constructor_ref),
            signer::address_of(user2),
            USER2_TOKENS
        );

        primary_fungible_store::mint(
            &fungible_asset::generate_mint_ref(fa_obj_constructor_ref),
            signer::address_of(user3),
            USER3_TOKENS
        );

        // Initialize treasury module with the fungible asset
        treasury::init_module_for_test_with_fa(aptos_framework, admin, object::object_from_constructor_ref<Metadata>(fa_obj_constructor_ref));
    }

    #[test(aptos_framework = @std, admin = @tidmat, user1 = @0x123, user2 = @0x456, user3 = @0x789)]
    fun test_subscribe_basic_monthly_success(aptos_framework: &signer, admin: &signer, user1: &signer, user2: &signer, user3: &signer) {
        setup_test_environment(aptos_framework, admin, user1, user2, user3);

        // Subscribe to basic tier for one month
        subscription::subscribe(user1, subscription::tier_basic(), subscription::period_monthly());

        // Verify subscription
        assert!(subscription::is_subscription_active(signer::address_of(user1)), 1);
        assert!(subscription::get_subscription_tier(signer::address_of(user1)) == subscription::tier_basic(), 2);
        
        let expected_end_time = 1000 + subscription::period_monthly();
        assert!(subscription::get_subscription_end_time(signer::address_of(user1)) == expected_end_time, 3);
    }

    #[test(aptos_framework = @std, admin = @tidmat, user1 = @0x123, user2 = @0x456, user3 = @0x789)]
    fun test_subscribe_pro_yearly_success(aptos_framework: &signer, admin: &signer, user1: &signer, user2: &signer, user3: &signer) {
        setup_test_environment(aptos_framework, admin, user1, user2, user3);

        // Subscribe to pro tier for one year
        subscription::subscribe(user1, subscription::tier_pro(), subscription::period_yearly());

        // Verify subscription
        assert!(subscription::is_subscription_active(signer::address_of(user1)), 1);
        assert!(subscription::get_subscription_tier(signer::address_of(user1)) == subscription::tier_pro(), 2);
        
        let expected_end_time = 1000 + subscription::period_yearly();
        assert!(subscription::get_subscription_end_time(signer::address_of(user1)) == expected_end_time, 3);
    }

    #[test(aptos_framework = @std, admin = @tidmat, user1 = @0x123, user2 = @0x456, user3 = @0x789)]
    #[expected_failure(abort_code = subscription::ESUBSCRIPTION_ALREADY_EXISTS)]
    fun test_subscribe_already_exists(aptos_framework: &signer, admin: &signer, user1: &signer, user2: &signer, user3: &signer) {
        setup_test_environment(aptos_framework, admin, user1, user2, user3);

        // Subscribe the first time
        subscription::subscribe(user1, subscription::tier_basic(), subscription::period_monthly());
        
        // Try to subscribe again - should fail
        subscription::subscribe(user1, subscription::tier_pro(), subscription::period_monthly());
    }

    #[test(aptos_framework = @std, admin = @tidmat, user1 = @0x123, user2 = @0x456, user3 = @0x789)]
    #[expected_failure(abort_code = subscription::EINVALID_SUBSCRIPTION_TIER)]
    fun test_subscribe_invalid_tier(aptos_framework: &signer, admin: &signer, user1: &signer, user2: &signer, user3: &signer) {
        setup_test_environment(aptos_framework, admin, user1, user2, user3);

        // Try to subscribe with invalid tier (4)
        subscription::subscribe(user1, 4, subscription::period_monthly());
    }

    #[test(aptos_framework = @std, admin = @tidmat, user1 = @0x123, user2 = @0x456, user3 = @0x789)]
    #[expected_failure(abort_code = subscription::ENOT_ENOUGH_BAL)]
    fun test_subscribe_insufficient_balance(aptos_framework: &signer, admin: &signer, user1: &signer, user2: &signer, user3: &signer) {
        setup_test_environment(aptos_framework, admin, user1, user2, user3);

        // User2 has only 50 tokens, insufficient for yearly enterprise subscription
        subscription::subscribe(user2, subscription::tier_enterprise(), subscription::period_yearly());
    }

    #[test(aptos_framework = @std, admin = @tidmat, user1 = @0x123, user2 = @0x456, user3 = @0x789)]
    fun test_renew_subscription_success(aptos_framework: &signer, admin: &signer, user1: &signer, user2: &signer, user3: &signer) {
        setup_test_environment(aptos_framework, admin, user1, user2, user3);

        // Subscribe first
        subscription::subscribe(user1, subscription::tier_basic(), subscription::period_monthly());
        let initial_end_time = subscription::get_subscription_end_time(signer::address_of(user1));
        
        // Renew subscription
        subscription::renew_subscription(user1, subscription::period_monthly());
        
        // Verify renewal
        let new_end_time = subscription::get_subscription_end_time(signer::address_of(user1));
        assert!(new_end_time == initial_end_time + subscription::period_monthly(), 1);
    }

    #[test(aptos_framework = @std, admin = @tidmat, user1 = @0x123, user2 = @0x456, user3 = @0x789)]
    #[expected_failure(abort_code = subscription::ESUBSCRIPTION_NOT_FOUND)]
    fun test_renew_subscription_not_found(aptos_framework: &signer, admin: &signer, user1: &signer, user2: &signer, user3: &signer) {
        setup_test_environment(aptos_framework, admin, user1, user2, user3);

        // Try to renew non-existent subscription
        subscription::renew_subscription(user1, subscription::period_monthly());
    }

    #[test(aptos_framework = @std, admin = @tidmat, user1 = @0x123, user2 = @0x456, user3 = @0x789)]
    fun test_upgrade_subscription_success(aptos_framework: &signer, admin: &signer, user1: &signer, user2: &signer, user3: &signer) {
        setup_test_environment(aptos_framework, admin, user1, user2, user3);

        // Subscribe to basic tier
        subscription::subscribe(user1, subscription::tier_basic(), subscription::period_monthly());
        assert!(subscription::get_subscription_tier(signer::address_of(user1)) == subscription::tier_basic(), 1);
        
        // Upgrade to pro tier
        subscription::upgrade_subscription(user1, subscription::tier_pro());
        
        // Verify upgrade
        assert!(subscription::get_subscription_tier(signer::address_of(user1)) == subscription::tier_pro(), 2);
    }

    #[test(aptos_framework = @std, admin = @tidmat, user1 = @0x123, user2 = @0x456, user3 = @0x789)]
    #[expected_failure(abort_code = subscription::EINVALID_SUBSCRIPTION_TIER)]
    fun test_upgrade_subscription_invalid_tier(aptos_framework: &signer, admin: &signer, user1: &signer, user2: &signer, user3: &signer) {
        setup_test_environment(aptos_framework, admin, user1, user2, user3);

        // Subscribe to pro tier
        subscription::subscribe(user1, subscription::tier_pro(), subscription::period_monthly());
        
        // Try to "upgrade" to basic tier (which is lower)
        subscription::upgrade_subscription(user1, subscription::tier_basic());
    }

    #[test(aptos_framework = @std, admin = @tidmat, user1 = @0x123, user2 = @0x456, user3 = @0x789)]
    fun test_subscription_expiration(aptos_framework: &signer, admin: &signer, user1: &signer, user2: &signer, user3: &signer) {
        setup_test_environment(aptos_framework, admin, user1, user2, user3);

        // Subscribe for one month
        subscription::subscribe(user1, subscription::tier_basic(), subscription::period_monthly());
        assert!(subscription::is_subscription_active(signer::address_of(user1)), 1);
        
        // Fast forward time to after expiration
        timestamp::update_global_time_for_test_secs(subscription::period_monthly() + 1000 + 1);
        
        // Verify subscription is no longer active
        assert!(!subscription::is_subscription_active(signer::address_of(user1)), 2);
    }

    #[test(aptos_framework = @std, admin = @tidmat, user1 = @0x123, user2 = @0x456, user3 = @0x789)]
    fun test_multiple_users_different_tiers(aptos_framework: &signer, admin: &signer, user1: &signer, user2: &signer, user3: &signer) {
        setup_test_environment(aptos_framework, admin, user1, user2, user3);

        // User1 subscribes to Basic
        subscription::subscribe(user1, subscription::tier_basic(), subscription::period_monthly());
        assert!(subscription::get_subscription_tier(signer::address_of(user1)) == subscription::tier_basic(), 1);
        
        // User3 subscribes to Pro
        subscription::subscribe(user3, subscription::tier_pro(), subscription::period_monthly());
        assert!(subscription::get_subscription_tier(signer::address_of(user3)) == subscription::tier_pro(), 2);
        
        // Both subscriptions should be active
        assert!(subscription::is_subscription_active(signer::address_of(user1)), 3);
        assert!(subscription::is_subscription_active(signer::address_of(user3)), 4);
    }

    #[test(aptos_framework = @std, admin = @tidmat, user1 = @0x123, user2 = @0x456, user3 = @0x789)]
    fun test_renew_then_upgrade(aptos_framework: &signer, admin: &signer, user1: &signer, user2: &signer, user3: &signer) {
        setup_test_environment(aptos_framework, admin, user1, user2, user3);

        // Subscribe to basic tier
        subscription::subscribe(user1, subscription::tier_basic(), subscription::period_monthly());
        let initial_end_time = subscription::get_subscription_end_time(signer::address_of(user1));
        
        // Renew subscription
        subscription::renew_subscription(user1, subscription::period_monthly());
        let renewed_end_time = subscription::get_subscription_end_time(signer::address_of(user1));
        assert!(renewed_end_time == initial_end_time + subscription::period_monthly(), 1);
        
        // Then upgrade to pro
        subscription::upgrade_subscription(user1, subscription::tier_pro());
        
        // Tier should be updated but end time should remain the same
        assert!(subscription::get_subscription_tier(signer::address_of(user1)) == subscription::tier_pro(), 2);
        assert!(subscription::get_subscription_end_time(signer::address_of(user1)) == renewed_end_time, 3);
    }

    #[test(aptos_framework = @std, admin = @tidmat, user1 = @0x123, user2 = @0x456, user3 = @0x789)]
    fun test_upgrade_then_renew(aptos_framework: &signer, admin: &signer, user1: &signer, user2: &signer, user3: &signer) {
        setup_test_environment(aptos_framework, admin, user1, user2, user3);

        // Subscribe to basic tier
        subscription::subscribe(user1, subscription::tier_basic(), subscription::period_monthly());
        let initial_end_time = subscription::get_subscription_end_time(signer::address_of(user1));
        
        // Upgrade to pro
        subscription::upgrade_subscription(user1, subscription::tier_pro());
        assert!(subscription::get_subscription_tier(signer::address_of(user1)) == subscription::tier_pro(), 1);
        
        // Then renew
        subscription::renew_subscription(user1, subscription::period_monthly());
        
        // End time should be extended
        assert!(subscription::get_subscription_end_time(signer::address_of(user1)) == initial_end_time + subscription::period_monthly(), 2);
        
        // Tier should still be pro
        assert!(subscription::get_subscription_tier(signer::address_of(user1)) == subscription::tier_pro(), 3);
    }
}
