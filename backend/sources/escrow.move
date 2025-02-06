module tidmat::escrow {
    use std::error;
    use std::signer;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::timestamp;
    use aptos_framework::account;
    use aptos_framework::event;

    /// Error codes
    const EINVALID_AMOUNT: u64 = 1;
    const EINVALID_STATE: u64 = 2;
    const ENOT_CREATOR: u64 = 3;
    const ENOT_CONTRIBUTOR: u64 = 4;
    const EESCROW_NOT_FUNDED: u64 = 5;
    const EESCROW_ALREADY_EXISTS: u64 = 6;
    const EESCROW_DOESNT_EXIST: u64 = 7;

    struct EscrowState has copy, drop, store {
        is_active: bool,
        is_funded: bool,
        is_released: bool,
        is_refunded: bool,
    }

    struct EscrowEvent has drop, store {
        creator: address,
        contributor: address,
        amount: u64,
        timestamp: u64,
        action: u8, // 1: create, 2: fund, 3: release, 4: refund
    }


    struct Escrow<phantom CoinType> has key {
        creator: address,
        contributor: address,
        amount: u64,
        state: EscrowState,
        creation_time: u64,
        funds: Coin<CoinType>,
        escrow_events: event::EventHandle<EscrowEvent>
    }


    public entry fun create_escrow<CoinType>(
        creator: &signer,
        contributor_address: address,
        amount: u64
    ) {
        let creator_addr = signer::address_of(creator);
        
        assert!(amount > 0, error::invalid_argument(EINVALID_AMOUNT));
        assert!(!exists<Escrow<CoinType>>(creator_addr), error::already_exists(EESCROW_ALREADY_EXISTS));

        let escrow = Escrow<CoinType> {
            creator: creator_addr,
            contributor: contributor_address,
            amount,
            state: EscrowState {
                is_active: true,
                is_funded: false,
                is_released: false,
                is_refunded: false,
            },
            creation_time: timestamp::now_seconds(),
            funds: coin::zero<CoinType>(),
            escrow_events: account::new_event_handle<EscrowEvent>(creator)
        };

        event::emit_event(&mut escrow.escrow_events, EscrowEvent {
            creator: creator_addr,
            contributor: contributor_address,
            amount,
            timestamp: timestamp::now_seconds(),
            action: 1
        });

        move_to(creator, escrow);
    }

    public entry fun fund_escrow<CoinType>(
        contributor: &signer,
        creator_address: address,
    ) acquires Escrow {
        let contributor_addr = signer::address_of(contributor);
        
        assert!(exists<Escrow<CoinType>>(creator_address), error::not_found(EESCROW_DOESNT_EXIST));
        let escrow = borrow_global_mut<Escrow<CoinType>>(creator_address);
        assert!(escrow.contributor == contributor_addr, error::permission_denied(ENOT_CONTRIBUTOR));
        assert!(escrow.state.is_active && !escrow.state.is_funded, error::invalid_state(EINVALID_STATE));

        let payment = coin::withdraw<CoinType>(contributor, escrow.amount);
        coin::merge(&mut escrow.funds, payment);
        escrow.state.is_funded = true;

        event::emit_event(&mut escrow.escrow_events, EscrowEvent {
            creator: escrow.creator,
            contributor: contributor_addr,
            amount: escrow.amount,
            timestamp: timestamp::now_seconds(),
            action: 2
        });
    }


    public entry fun release_funds<CoinType>(
        creator: &signer,
        contributor_address: address,
    ) acquires Escrow {
        let creator_addr = signer::address_of(creator);
        
        assert!(exists<Escrow<CoinType>>(contributor_address), error::not_found(EESCROW_DOESNT_EXIST));
        let escrow = borrow_global_mut<Escrow<CoinType>>(contributor_address);
        assert!(escrow.creator == creator_addr, error::permission_denied(ENOT_CREATOR));
        assert!(escrow.state.is_funded && !escrow.state.is_released, error::invalid_state(EINVALID_STATE));

        let funds = coin::extract_all(&mut escrow.funds);
        coin::deposit(contributor_address, funds);
        escrow.state.is_released = true;
        escrow.state.is_active = false;

        event::emit_event(&mut escrow.escrow_events, EscrowEvent {
            creator: creator_addr,
            contributor: contributor_address,
            amount: escrow.amount,
            timestamp: timestamp::now_seconds(),
            action: 3
        });
    }


    public entry fun refund<CoinType>(
        creator: &signer,
        contributor_address: address,
    ) acquires Escrow {
        let creator_addr = signer::address_of(creator);
        
        assert!(exists<Escrow<CoinType>>(creator_addr), error::not_found(EESCROW_DOESNT_EXIST));
        let escrow = borrow_global_mut<Escrow<CoinType>>(creator_addr);
        assert!(escrow.creator == creator_addr, error::permission_denied(ENOT_CREATOR));
        assert!(escrow.state.is_funded && !escrow.state.is_refunded, error::invalid_state(EINVALID_STATE));

        let funds = coin::extract_all(&mut escrow.funds);
        coin::deposit(contributor_address, funds);
        escrow.state.is_refunded = true;
        escrow.state.is_active = false;

        event::emit_event(&mut escrow.escrow_events, EscrowEvent {
            creator: creator_addr,
            contributor: contributor_address,
            amount: escrow.amount,
            timestamp: timestamp::now_seconds(),
            action: 4
        });
    }

    #[view]
    public fun get_escrow_state<CoinType>(creator_address: address): EscrowState acquires Escrow {
        assert!(exists<Escrow<CoinType>>(creator_address), error::not_found(EESCROW_DOESNT_EXIST));
        let escrow = borrow_global<Escrow<CoinType>>(creator_address);
        escrow.state
    }

    #[view]
    public fun get_escrow_amount<CoinType>(creator_address: address): u64 acquires Escrow {
        assert!(exists<Escrow<CoinType>>(creator_address), error::not_found(EESCROW_DOESNT_EXIST));
        let escrow = borrow_global<Escrow<CoinType>>(creator_address);
        escrow.amount
    }

    #[view]
    public fun get_is_active<CoinType>(creator_address: address): bool acquires Escrow {
        assert!(exists<Escrow<CoinType>>(creator_address), error::not_found(EESCROW_DOESNT_EXIST));
        let escrow = borrow_global<Escrow<CoinType>>(creator_address);
        escrow.state.is_active
    }

    #[view]
    public fun get_is_funded<CoinType>(creator_address: address): bool acquires Escrow {
        assert!(exists<Escrow<CoinType>>(creator_address), error::not_found(EESCROW_DOESNT_EXIST));
        let escrow = borrow_global<Escrow<CoinType>>(creator_address);
        escrow.state.is_funded
    }

    #[view]
    public fun get_is_released<CoinType>(creator_address: address): bool acquires Escrow {
        assert!(exists<Escrow<CoinType>>(creator_address), error::not_found(EESCROW_DOESNT_EXIST));
        let escrow = borrow_global<Escrow<CoinType>>(creator_address);
        escrow.state.is_released
    }

    #[view]
    public fun get_is_refunded<CoinType>(creator_address: address): bool acquires Escrow {
        assert!(exists<Escrow<CoinType>>(creator_address), error::not_found(EESCROW_DOESNT_EXIST));
        let escrow = borrow_global<Escrow<CoinType>>(creator_address);
        escrow.state.is_refunded
    }
}