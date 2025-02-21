module tidmat::subscription_test {
    use std::signer;
    use aptos_framework::timestamp;
    use tidmat::subscription;
    use tidmat::treasury;

    /// Test subscribing to a tier
    public entry fun test_subscribe(admin: &signer, user: &signer) {
        // Initialize treasury to allow payments
        treasury::initialize_treasury(admin);

        // User subscribes to Basic Tier for a monthly duration
        subscription::subscribe(user, subscription::tier_basic(), subscription::period_monthly());

        // Check that the subscription exists
        assert!(subscription::is_subscription_active(signer::address_of(user)), 1);
    }

    /// Test renewing a subscription without using 'acquires'
    public entry fun test_renew_subscription(user: &signer) {
        let user_addr = signer::address_of(user);
        assert!(subscription::is_subscription_active(user_addr), 1);

        let initial_end_time = subscription::get_subscription_end_time(user_addr);

        // Renew for another month
        subscription::renew_subscription(user, subscription::period_monthly());

        let new_end_time = subscription::get_subscription_end_time(user_addr);
        assert!(new_end_time > initial_end_time, 2);
    }

    /// Test upgrading a subscription
    public entry fun test_upgrade_subscription(user: &signer) {
        let user_addr = signer::address_of(user);
        assert!(subscription::is_subscription_active(user_addr), 1);

        let initial_tier = subscription::get_subscription_tier(user_addr);

        // Upgrade to Pro tier
        subscription::upgrade_subscription(user, subscription::tier_pro());

        let new_tier = subscription::get_subscription_tier(user_addr);
        assert!(new_tier > initial_tier, 3);
    }

    /// Test checking subscription status
    #[view]
    public fun test_check_subscription_status(user_addr: address): bool {
        subscription::is_subscription_active(user_addr)
    }
}
