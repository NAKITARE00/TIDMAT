module tidmat::treasury_test {
    use std::signer;
    use std::vector;
    use aptos_framework::object::{Self, Object};
    use aptos_framework::fungible_asset::{Self, Metadata, FungibleAsset};
    use aptos_framework::primary_fungible_store;
    use tidmat::treasury;
    
    // Test initialization of treasury
    public entry fun test_initialize(admin: &signer) {
        treasury::initialize_treasury(admin);
    }
    
    // Test admin check function
    public entry fun test_admin_check(admin: &signer) {
        treasury::assert_admin(admin);
    }
    
    // Test processing a payment
    public entry fun test_process_payment(payer: &signer, amount: u64) {
        treasury::process_payment(payer, amount);
    }
    
    // Test withdrawing funds
    public entry fun test_withdraw_funds(admin: &signer){
        treasury::withdraw_funds(admin);
    }
    
    // Test getting treasury balance
    #[view]
    public fun test_get_treasury_balance(): u64 {
        treasury::get_treasury_bal()
    }
}