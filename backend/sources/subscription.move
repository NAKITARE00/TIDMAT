module tidmat::subscription {
    use std::error;
    use std::signer;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::timestamp;
    use aptos_framework::account;
    use aptos_framework::event;

    /// Error codes
    const EINVALID_SUBSCRIPTION_TIER: u64 = 1;
    const ESUBSCRIPTION_ALREADY_EXISTS: u64 = 2;
    const ESUBSCRIPTION_NOT_FOUND: u64 = 3;
    const ESUBSCRIPTION_EXPIRED: u64 = 4;
    const EINVALID_PAYMENT: u64 = 5;
    const ENOT_AUTHORIZED: u64 = 6;

    /// Subscription tiers
    const TIER_BASIC: u8 = 1;
    const TIER_PRO: u8 = 2;
    const TIER_ENTERPRISE: u8 = 3;

    /// Subscription periods (in seconds)
    const PERIOD_MONTHLY: u64 = 2592000; // 30 days
    const PERIOD_YEARLY: u64 = 31536000; // 365 days

    struct SubscriptionEvent has drop, store {
        subscriber: address,
        tier: u8,
        action: u8, // 1: subscribe, 2: renew, 3: upgrade, 4: cancel
        timestamp: u64
    }

    struct Subscription has key {
        tier: u8,
        start_time: u64,
        end_time: u64,
        is_active: bool,
        total_paid: u64,
        subscription_events: event::EventHandle<SubscriptionEvent>
    }

    struct SubscriptionTreasury<phantom CoinType> has key {
        funds: Coin<CoinType>,
        total_collected: u64,
        admin: address
    }

    public entry fun initialize_treasury<CoinType>(admin: &signer) {
        move_to(admin, SubscriptionTreasury<CoinType> {
            funds: coin::zero<CoinType>(),
            total_collected: 0,
            admin: signer::address_of(admin)
        });
    }

    public entry fun subscribe<CoinType>(
        subscriber: &signer,
        tier: u8,
        duration: u64
    ) acquires SubscriptionTreasury {
        let subscriber_addr = signer::address_of(subscriber);
        
        assert!(tier <= TIER_ENTERPRISE, error::invalid_argument(EINVALID_SUBSCRIPTION_TIER));
        assert!(!exists<Subscription>(subscriber_addr), error::already_exists(ESUBSCRIPTION_ALREADY_EXISTS));

        let cost = calculate_subscription_cost(tier, duration);
        
        let payment = coin::withdraw<CoinType>(subscriber, cost);
        process_payment(payment);

        let now = timestamp::now_seconds();
        let subscription = Subscription {
            tier,
            start_time: now,
            end_time: now + duration,
            is_active: true,
            total_paid: cost,
            subscription_events: account::new_event_handle<SubscriptionEvent>(subscriber)
        };

        event::emit_event(&mut subscription.subscription_events, SubscriptionEvent {
            subscriber: subscriber_addr,
            tier,
            action: 1,
            timestamp: now
        });

        move_to(subscriber, subscription);
    }

    public entry fun renew_subscription<CoinType>(
        subscriber: &signer,
        duration: u64
    ) acquires Subscription, SubscriptionTreasury {
        let subscriber_addr = signer::address_of(subscriber);
        assert!(exists<Subscription>(subscriber_addr), error::not_found(ESUBSCRIPTION_NOT_FOUND));
        
        let subscription = borrow_global_mut<Subscription>(subscriber_addr);
        let cost = calculate_subscription_cost(subscription.tier, duration);
        
        let payment = coin::withdraw<CoinType>(subscriber, cost);
        process_payment(payment);

        subscription.end_time = subscription.end_time + duration;
        subscription.total_paid = subscription.total_paid + cost;
        
        event::emit_event(&mut subscription.subscription_events, SubscriptionEvent {
            subscriber: subscriber_addr,
            tier: subscription.tier,
            action: 2,
            timestamp: timestamp::now_seconds()
        });
    }

    public entry fun upgrade_subscription<CoinType>(
        subscriber: &signer,
        new_tier: u8
    ) acquires Subscription, SubscriptionTreasury {
        let subscriber_addr = signer::address_of(subscriber);
        assert!(exists<Subscription>(subscriber_addr), error::not_found(ESUBSCRIPTION_NOT_FOUND));
        
        let subscription = borrow_global_mut<Subscription>(subscriber_addr);
        assert!(new_tier > subscription.tier, error::invalid_argument(EINVALID_SUBSCRIPTION_TIER));
        
        let remaining_time = subscription.end_time - timestamp::now_seconds();
        let upgrade_cost = calculate_upgrade_cost(subscription.tier, new_tier, remaining_time);
        
        let payment = coin::withdraw<CoinType>(subscriber, upgrade_cost);
        process_payment(payment);

        subscription.tier = new_tier;
        subscription.total_paid = subscription.total_paid + upgrade_cost;
        
        event::emit_event(&mut subscription.subscription_events, SubscriptionEvent {
            subscriber: subscriber_addr,
            tier: new_tier,
            action: 3,
            timestamp: timestamp::now_seconds()
        });
    }

    public entry fun withdraw_funds<CoinType>(
        admin: &signer,
        amount: u64
    ) acquires SubscriptionTreasury {
        let treasury = borrow_global_mut<SubscriptionTreasury<CoinType>>(@tidmat);
        assert!(signer::address_of(admin) == treasury.admin, error::permission_denied(ENOT_AUTHORIZED));
        
        let withdrawal = coin::extract(&mut treasury.funds, amount);
        coin::deposit(treasury.admin, withdrawal);
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
        assert!(exists<Subscription>(subscriber_address), error::not_found(ESUBSCRIPTION_NOT_FOUND));
        let subscription = borrow_global<Subscription>(subscriber_address);
        subscription.tier
    }

    #[view]
    public fun get_subscription_end_time(subscriber_address: address): u64 acquires Subscription {
        assert!(exists<Subscription>(subscriber_address), error::not_found(ESUBSCRIPTION_NOT_FOUND));
        let subscription = borrow_global<Subscription>(subscriber_address);
        subscription.end_time
    }

    fun calculate_subscription_cost(tier: u8, duration: u64): u64 {
        let base_cost = if (tier == TIER_BASIC) {
            10
        } else if (tier == TIER_PRO) {
            25
        } else {
            100
        };
        base_cost * (duration / PERIOD_MONTHLY)
    }

    fun calculate_upgrade_cost(current_tier: u8, new_tier: u8, remaining_time: u64): u64 {
        let current_monthly = calculate_subscription_cost(current_tier, PERIOD_MONTHLY);
        let new_monthly = calculate_subscription_cost(new_tier, PERIOD_MONTHLY);
        ((new_monthly - current_monthly) * remaining_time) / PERIOD_MONTHLY
    }

    fun process_payment<CoinType>(payment: Coin<CoinType>) acquires SubscriptionTreasury {
        let treasury = borrow_global_mut<SubscriptionTreasury<CoinType>>(@tidmat);
        coin::merge(&mut treasury.funds, payment);
        treasury.total_collected = treasury.total_collected + coin::value(&treasury.funds);
    }
}