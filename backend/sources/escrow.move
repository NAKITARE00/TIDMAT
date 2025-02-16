module tidmat::escrow {
    use std::signer;
    use std::error;
    use std::vector;
    use aptos_std::math64;
    use aptos_framework::object::Object;
    use tidmat::stake;
    use tidmat::treasury;
    use tidmat::contribution;

    const EINSUFFICIENT_FUNDS: u64 = 1;
    const ENO_ACTIVE_ESCROW: u64 = 2;
    const EUNAUTHORIZED_ACCESS: u64 = 3;
    const EINCOMPLETE_CAMPAIGN: u64 = 4;

    struct Escrow has key, store, drop, copy {
        campaign_id: u64,
        creator: address,
	total_locked: u64,
	pool_bal: u64,
        locked_funds: Object<stake::StakePool>
    }

    public fun create_escrow(
        creator: &signer,
        campaign_id: u64,
        total_reward_pool: u64
    ): Escrow {
        let creator_addr = signer::address_of(creator);
        assert!(total_reward_pool > 0, error::invalid_argument(EINSUFFICIENT_FUNDS));

	let pool = stake::create_stake_pool(creator, total_reward_pool);

        let escrow =  Escrow {
            campaign_id,
            creator: creator_addr,
	    total_locked: total_reward_pool,
	    pool_bal: total_reward_pool,
            locked_funds: pool,
        };

	escrow
    }

    public fun refund(
        creator: &signer,
	escrow: Escrow,	
        apply_fee: bool
    )  {
	assert!(signer::address_of(creator) == escrow.creator, EUNAUTHORIZED_ACCESS);
	
	let refund_amount = escrow.total_locked;
        let fee = if (apply_fee) {
           math64::mul_div(refund_amount, 90, 100)
        } else {
            0
        };

	let final_refund = refund_amount - fee;
	stake::transfer_from_pool(
	    escrow.locked_funds, 
	    escrow.creator,
	    final_refund
	);
	
	escrow.pool_bal = escrow.pool_bal - final_refund;
    }

    public fun release_funds(
	creator: &signer,
        escrow: Escrow,
        contributions: vector<contribution::Contribution>,
        verified_contributions: u64
    ) {
        assert!(verified_contributions > 0, error::invalid_state(EINCOMPLETE_CAMPAIGN));

	let pool_bal = stake::get_pool_bal(escrow.locked_funds);

	// Marketplace Cut
	let cut = math64::mul_div(pool_bal, 1, 100);
	treasury::process_payment(creator, cut);

	let new_pool_bal = pool_bal - cut;

        let per_contributor_reward = new_pool_bal / verified_contributions;
        assert!(per_contributor_reward > 0, error::invalid_argument(EINSUFFICIENT_FUNDS));

        let i = 0;
        let len = vector::length(&contributions);
        while (i < len) {
            let contribution = vector::borrow(&contributions, i);
	    let contributor = contribution::get_contributor_addr(contribution);
	    stake::transfer_from_pool(
		escrow.locked_funds,
		contributor,
		per_contributor_reward
	    );	
            i = i + 1;
        }; 
    }

    public fun get_escrow_pool_bal(escrow: Escrow): u64 {
	escrow.pool_bal
    }	 
}
