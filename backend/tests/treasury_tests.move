#[test_only]
module tidmat::treasury_tests {
    use std::signer;
    use std::error;
    use aptos_framework::timestamp;
    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_framework::object;
    use aptos_framework::primary_fungible_store;
    use std::string;
    use std::option;
    use tidmat::treasury;

    const ADMIN: address = @tidmat;
    const USER: address = @0x456;
    const INITIAL_BALANCE: u64 = 10000;
    const PAYMENT_AMOUNT: u64 = 500;

    // Setup function to initialize the testing environment
    fun setup_fa(aptos_framework: &signer, admin: &signer, user: &signer): object::Object<Metadata> {
        // Start timestamp for testing
        timestamp::set_time_has_started_for_testing(aptos_framework);
        timestamp::update_global_time_for_test_secs(1000);

        // Create fungible asset for testing
        let owner_addr = signer::address_of(admin);
        let user_addr = signer::address_of(user);
        
        // Create a fungible asset
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
	
	// Mint tokens to admin for testing
	primary_fungible_store::mint(
	    &fungible_asset::generate_mint_ref(fa_obj_constructor_ref),
	    owner_addr,
	    INITIAL_BALANCE
	);
        
        // Mint tokens to user for testing
        primary_fungible_store::mint(
            &fungible_asset::generate_mint_ref(fa_obj_constructor_ref),
            user_addr,
            INITIAL_BALANCE
        );

        // Return the fungible asset object
        object::object_from_constructor_ref<Metadata>(fa_obj_constructor_ref)
    }

    #[test(aptos_framework = @std, admin = @tidmat, user = @0x456)]
    fun test_treasury_initialization(aptos_framework: &signer, admin: &signer, user: &signer) {
        let fa_metadata = setup_fa(aptos_framework, admin, user);
        
        // Initialize treasury module with the fungible asset
        treasury::init_module_for_test_with_fa(aptos_framework, admin, fa_metadata);
        
        // Verify treasury was initialized with zero balance
        let balance = treasury::get_treasury_bal();
        assert!(balance == 0, 1);
        
        // Verify the fungible asset metadata is correctly stored
        let stored_fa_metadata = treasury::get_fa_metadata();
        assert!(object::object_address(&stored_fa_metadata) == object::object_address(&fa_metadata), 2);
    }

    #[test(aptos_framework = @std, admin = @tidmat, user = @0x456)]
    fun test_process_payment(aptos_framework: &signer, admin: &signer, user: &signer) {
        let fa_metadata = setup_fa(aptos_framework, admin, user);
        
        // Initialize treasury module
        treasury::init_module_for_test_with_fa(aptos_framework, admin, fa_metadata);
        
        // Get user's store
        let user_store = primary_fungible_store::primary_store(signer::address_of(user), fa_metadata);
        
        // Process a payment
        treasury::process_payment(user, user_store, PAYMENT_AMOUNT);
        
        // Verify treasury balance increased
        let balance = treasury::get_treasury_bal();
        assert!(balance == PAYMENT_AMOUNT, 1);
        
        // Verify user balance decreased
        let user_balance = fungible_asset::balance(user_store);
        assert!(user_balance == INITIAL_BALANCE - PAYMENT_AMOUNT, 2);
    }
    
    #[test(aptos_framework = @std, admin = @tidmat, user = @0x456)]
    #[expected_failure(abort_code = treasury::ENOT_ENOUGH_BAL)]
    fun test_process_payment_insufficient_funds(aptos_framework: &signer, admin: &signer, user: &signer) {
        let fa_metadata = setup_fa(aptos_framework, admin, user);
        
        // Initialize treasury module
        treasury::init_module_for_test_with_fa(aptos_framework, admin, fa_metadata);
        
        // Get user's store
        let user_store = primary_fungible_store::primary_store(signer::address_of(user), fa_metadata);
        
        // Try to process a payment larger than the user's balance
        let too_large_amount = INITIAL_BALANCE + 1;
        treasury::process_payment(user, user_store, too_large_amount);
    }

    #[test(aptos_framework = @std, admin = @tidmat, user = @0x456)]
    fun test_withdraw_funds(aptos_framework: &signer, admin: &signer, user: &signer) {
        let fa_metadata = setup_fa(aptos_framework, admin, user);
        
        // Initialize treasury module
        treasury::init_module_for_test_with_fa(aptos_framework, admin, fa_metadata);
        
        // Get user's store
        let user_store = primary_fungible_store::primary_store(signer::address_of(user), fa_metadata);
        
        // Process a payment to have funds in treasury
        treasury::process_payment(user, user_store, PAYMENT_AMOUNT);
        
        // Record admin's balance before withdrawal
        let admin_store = primary_fungible_store::primary_store(signer::address_of(admin), fa_metadata);
        let admin_balance_before = fungible_asset::balance(admin_store);
        
        // Withdraw funds
        treasury::withdraw_funds(admin);
        
        // Verify treasury balance is now zero
        let treasury_balance = treasury::get_treasury_bal();
        assert!(treasury_balance == PAYMENT_AMOUNT, 1);
        
        // Verify admin received the funds
        let admin_balance_after = fungible_asset::balance(admin_store);
        assert!(admin_balance_after == admin_balance_before + PAYMENT_AMOUNT, 2);
    }

    #[test(aptos_framework = @std, admin = @tidmat, user = @0x456)]
    #[expected_failure(abort_code = treasury::UNAUTHORIZED)]
    fun test_withdraw_funds_unauthorized(aptos_framework: &signer, admin: &signer, user: &signer) {
        let fa_metadata = setup_fa(aptos_framework, admin, user);
        
        // Initialize treasury module
        treasury::init_module_for_test_with_fa(aptos_framework, admin, fa_metadata);
        
        // Get user's store
        let user_store = primary_fungible_store::primary_store(signer::address_of(user), fa_metadata);
        
        // Process a payment to have funds in treasury
        treasury::process_payment(user, user_store, PAYMENT_AMOUNT);
        
        // Attempt unauthorized withdrawal (user is not admin)
        treasury::withdraw_funds(user);
    }

    #[test(aptos_framework = @std, admin = @tidmat, user = @0x456)]
    fun test_multiple_payments(aptos_framework: &signer, admin: &signer, user: &signer) {
        let fa_metadata = setup_fa(aptos_framework, admin, user);
        
        // Initialize treasury module
        treasury::init_module_for_test_with_fa(aptos_framework, admin, fa_metadata);
        
        // Get user's store
        let user_store = primary_fungible_store::primary_store(signer::address_of(user), fa_metadata);
        
        // Process multiple payments
        treasury::process_payment(user, user_store, PAYMENT_AMOUNT);
        treasury::process_payment(user, user_store, PAYMENT_AMOUNT);
        treasury::process_payment(user, user_store, PAYMENT_AMOUNT);
        
        // Verify treasury balance increased correctly
        let balance = treasury::get_treasury_bal();
        assert!(balance == PAYMENT_AMOUNT * 3, 1);
        
        // Verify user balance decreased correctly
        let user_balance = fungible_asset::balance(user_store);
        assert!(user_balance == INITIAL_BALANCE - (PAYMENT_AMOUNT * 3), 2);
    }

    #[test(aptos_framework = @std, admin = @tidmat, user = @0x456)]
    fun test_assert_admin(aptos_framework: &signer, admin: &signer, user: &signer) {
        let fa_metadata = setup_fa(aptos_framework, admin, user);
        
        // Initialize treasury module
        treasury::init_module_for_test_with_fa(aptos_framework, admin, fa_metadata);
        
        // This should pass without error
        treasury::assert_admin(admin);
    }

    #[test(aptos_framework = @std, admin = @tidmat, user = @0x456)]
    #[expected_failure(abort_code = treasury::UNAUTHORIZED)]
    fun test_assert_admin_unauthorized(aptos_framework: &signer, admin: &signer, user: &signer) {
        let fa_metadata = setup_fa(aptos_framework, admin, user);
        
        // Initialize treasury module
        treasury::init_module_for_test_with_fa(aptos_framework, admin, fa_metadata);
        
        // This should fail with UNAUTHORIZED error
        treasury::assert_admin(user);
    }

    #[test(aptos_framework = @std, admin = @tidmat, user = @0x456)]
    #[expected_failure(abort_code = treasury::ETREASURY_NOT_FOUND)]
    fun test_get_treasury_bal_not_initialized(aptos_framework: &signer, admin: &signer, user: &signer) {
        // Try to get treasury balance without initializing
        treasury::get_treasury_bal();
    }
}
