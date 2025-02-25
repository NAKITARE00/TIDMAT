module tidmat::subscription {
    use std::signer;
    use aptos_framework::timestamp;
    use aptos_framework::primary_fungible_store;
    use tidmat::treasury;

    /// Error codes
    const EINVALID_SUBSCRIPTION_TIER: u64 = 1;
    const ESUBSCRIPTION_ALREADY_EXISTS: u64 = 2;
    const ESUBSCRIPTION_NOT_FOUND: u64 = 3;
    const ESUBSCRIPTION_EXPIRED: u64 = 4;
    const EINVALID_PAYMENT: u64 = 5;
    const ENOT_AUTHORIZED: u64 = 6;
    const ENOT_ENOUGH_BAL: u64 = 7;

    /// Subscription tiers
    const TIER_BASIC: u8 = 1;
    const TIER_PRO: u8 = 2;
    const TIER_ENTERPRISE: u8 = 3;

    /// Subscription Cost
    const TIER_BASIC_BASE_COST: u64 = 10;
    const TIER_PRO_BASE_COST: u64 = 25;
    const TIER_ENTERPRISE_BASE_COST: u64 = 100;

    /// Subscription periods (in seconds)
    const PERIOD_MONTHLY: u64 = 2592000; // 30 days
    const PERIOD_YEARLY: u64 = 31536000; // 365 days

    /// Public function to get the basic tier value
    public fun tier_basic(): u8 {
        TIER_BASIC
    }

    /// Public function to get the pro tier value
    public fun tier_pro(): u8 {
        TIER_PRO
    }

    /// Public function to get the enterprise tier value
    public fun tier_enterprise(): u8 {
        TIER_ENTERPRISE
    }

    /// Public function to get the monthly period value
    public fun period_monthly(): u64 {
        PERIOD_MONTHLY
    }

    /// Public function to get the yearly period value
    public fun period_yearly(): u64 {
        PERIOD_YEARLY
    }

    struct Subscription has key {
        tier: u8,
        start_time: u64,
        end_time: u64,
        is_active: bool,
        total_paid: u64,
    }

    public entry fun subscribe(
        subscriber: &signer,
        tier: u8,
        duration: u64
    ) {
        let subscriber_addr = signer::address_of(subscriber);

        assert!(tier <= TIER_ENTERPRISE, EINVALID_SUBSCRIPTION_TIER);
        assert!(!exists<Subscription>(subscriber_addr), ESUBSCRIPTION_ALREADY_EXISTS);

        let cost = calculate_subscription_cost(tier, duration);

        let fa_metadata_object = treasury::get_fa_metadata();
        let subscriber_store_bal = primary_fungible_store::balance(subscriber_addr, fa_metadata_object);

        assert!(subscriber_store_bal >= cost, ENOT_ENOUGH_BAL);

        let subscriber_store = primary_fungible_store::primary_store(subscriber_addr, fa_metadata_object);

        treasury::process_payment(subscriber, subscriber_store, cost);

        let now = timestamp::now_seconds();
        let subscription = Subscription {
            tier,
            start_time: now,
            end_time: now + duration,
            is_active: true,
            total_paid: cost
        };

        move_to(subscriber, subscription);
    }

    public entry fun renew_subscription(
        subscriber: &signer,
        duration: u64
    ) acquires Subscription {
        let subscriber_addr = signer::address_of(subscriber);
        assert!(exists<Subscription>(subscriber_addr), ESUBSCRIPTION_NOT_FOUND);

        let subscription = borrow_global_mut<Subscription>(subscriber_addr);
        let cost = calculate_subscription_cost(subscription.tier, duration);

        let fa_metadata_object = treasury::get_fa_metadata();
        let subscriber_store_bal = primary_fungible_store::balance(subscriber_addr, fa_metadata_object);

        assert!(subscriber_store_bal >= cost, ENOT_ENOUGH_BAL);

        let subscriber_store = primary_fungible_store::primary_store(subscriber_addr, fa_metadata_object);

        treasury::process_payment(subscriber, subscriber_store, cost);

        subscription.end_time = subscription.end_time + duration;
        subscription.total_paid = subscription.total_paid + cost;
    }

    public entry fun upgrade_subscription(
        subscriber: &signer,
        new_tier: u8
    ) acquires Subscription {
        let subscriber_addr = signer::address_of(subscriber);
        assert!(exists<Subscription>(subscriber_addr), ESUBSCRIPTION_NOT_FOUND);

        let subscription = borrow_global_mut<Subscription>(subscriber_addr);
        assert!(new_tier > subscription.tier, EINVALID_SUBSCRIPTION_TIER);

        let remaining_time = subscription.end_time - timestamp::now_seconds();
        let upgrade_cost = calculate_upgrade_cost(subscription.tier, new_tier, remaining_time);

        let fa_metadata_object = treasury::get_fa_metadata();
        let subscriber_store_bal = primary_fungible_store::balance(subscriber_addr, fa_metadata_object);

        assert!(subscriber_store_bal >= upgrade_cost, ENOT_ENOUGH_BAL);

        let subscriber_store = primary_fungible_store::primary_store(subscriber_addr, fa_metadata_object);

        treasury::process_payment(subscriber, subscriber_store, upgrade_cost);

        subscription.tier = new_tier;
        subscription.total_paid = subscription.total_paid + upgrade_cost;
    }

    #[view]
    public fun is_subscription_active(subscriber_address: address): bool acquires Subscription {
        if (!exists<Subscription>(subscriber_address)) {
            return false
        };
        let subscription = borrow_global<Subscription>(subscriber_address);
        subscription.is_active && subscription.end_time > timestamp::now_seconds()
    }

    #[view]
    public fun get_subscription_tier(subscriber_address: address): u8 acquires Subscription {
        assert!(exists<Subscription>(subscriber_address), ESUBSCRIPTION_NOT_FOUND);
        let subscription = borrow_global<Subscription>(subscriber_address);
        subscription.tier
    }

    #[view]
    public fun get_subscription_end_time(subscriber_address: address): u64 acquires Subscription {
        assert!(exists<Subscription>(subscriber_address), ESUBSCRIPTION_NOT_FOUND);
        let subscription = borrow_global<Subscription>(subscriber_address);
        subscription.end_time
    }

    fun calculate_subscription_cost(tier: u8, duration: u64): u64 {
        let base_cost = if (tier == TIER_BASIC) {
            TIER_BASIC_BASE_COST
        } else if (tier == TIER_PRO) {
            TIER_PRO_BASE_COST
        } else {
            TIER_ENTERPRISE_BASE_COST
        };
        base_cost * (duration / PERIOD_MONTHLY)
    }

    fun calculate_upgrade_cost(current_tier: u8, new_tier: u8, remaining_time: u64): u64 {
        let current_monthly = calculate_subscription_cost(current_tier, PERIOD_MONTHLY);
        let new_monthly = calculate_subscription_cost(new_tier, PERIOD_MONTHLY);
        ((new_monthly - current_monthly) * remaining_time) / PERIOD_MONTHLY
    }
}
