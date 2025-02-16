module tidmat::contribution {
    use std::signer;
    use std::error;
    use std::vector;

    const ECONTRIBUTION_ALREADY_EXISTS: u64 = 1;
    const ECONTRIBUTION_NOT_FOUND: u64 = 2;
    const EINVALID_CONTRIBUTION_PARAMS: u64 = 3;
    const EUNAUTHORIZED_ACTION: u64 = 4;
    const ECAMPAIGN_NOT_FOUND: u64 = 5;
    const ETRACKER_NOT_FOUND: u64 = 6;

    const CONTRIBUTION_STATUS_SUBMITTED: u8 = 1;
    const CONTRIBUTION_STATUS_VERIFIED: u8 = 2;
    const CONTRIBUTION_STATUS_ACCEPTED: u8 = 3;
    const CONTRIBUTION_STATUS_REJECTED: u8 = 4;

    struct Contribution has key, store, drop, copy {
	contribution_id: u64,
        campaign_id: u64,
        contributor: address,
        data: vector<u8>,
        status: u8
    }

    struct ContributionTracker has key, store, copy {
        contributions: vector<Contribution>,
	next_contribution_id: u64
    }

    public fun init_contribution_module(
        c: &signer,
    ) {
        let tracker = ContributionTracker {
            contributions: vector::empty<Contribution>(),
	    next_contribution_id: 1
        };

	move_to(c, tracker);
    }

    #[view]
    public fun get_campaign_contributions(
        campaign_id: u64
    ): vector<u64> acquires ContributionTracker {
	assert!(exists<ContributionTracker>(@tidmat), error::not_found(ETRACKER_NOT_FOUND));	

	let tracker= borrow_global<ContributionTracker>(@tidmat);

        let i = 0;
        let contributions = vector::empty<u64>();
        let len  = vector::length<Contribution>(&tracker.contributions);
        while (i < len) {
            let contribution_ref = vector::borrow(&tracker.contributions, i);
            if (contribution_ref.campaign_id == campaign_id) {
                vector::push_back(&mut contributions, contribution_ref.contribution_id);
            };
            i = i + 1;
        };

        contributions
    }

    #[view]
    public fun get_contributor_details(
	contributor_id: u64
    ): (u64, address, vector<u8>, u8) acquires ContributionTracker {
	assert!(exists<ContributionTracker>(@tidmat), error::not_found(ETRACKER_NOT_FOUND));

	let tracker = borrow_global<ContributionTracker>(@tidmat);

	let c_idx = contributor_id - 1;
	let contribution_ref = vector::borrow(&tracker.contributions, c_idx);
	
	(
	    contribution_ref.campaign_id,
	    contribution_ref.contributor,
	    contribution_ref.data,
	    contribution_ref.status
	)
    }
  
    public fun get_contributor_addr(c: &Contribution): address {
	c.contributor
    }

    public fun get_contributions(): vector<Contribution> acquires ContributionTracker {
	assert!(exists<ContributionTracker>(@tidmat), error::not_found(ETRACKER_NOT_FOUND));
	let tracker = borrow_global<ContributionTracker>(@tidmat);
	tracker.contributions
    }

    public fun update_tracker_contributions(c: Contribution) acquires ContributionTracker {
	assert!(exists<ContributionTracker>(@tidmat), error::not_found(ETRACKER_NOT_FOUND));
	let tracker = borrow_global_mut<ContributionTracker>(@tidmat);
	vector::push_back(&mut tracker.contributions, c);
    }	

    public fun update_contrib_id(last_contrib_id: u64) acquires ContributionTracker {
	assert!(exists<ContributionTracker>(@tidmat), error::not_found(ETRACKER_NOT_FOUND));
	let tracker = borrow_global_mut<ContributionTracker>(@tidmat);
	tracker.next_contribution_id = last_contrib_id + 1;
    }

    public fun next_contrib_id(): u64 acquires ContributionTracker {
	assert!(exists<ContributionTracker>(@tidmat), error::not_found(ETRACKER_NOT_FOUND));
	let tracker = borrow_global<ContributionTracker>(@tidmat);
	tracker.next_contribution_id
    }	

    public fun update_contrib_status(status: u8, contrib_id: u64, campaign_id: u64) acquires ContributionTracker {
	assert!(status == CONTRIBUTION_STATUS_VERIFIED || status == CONTRIBUTION_STATUS_REJECTED, error::invalid_argument(EINVALID_CONTRIBUTION_PARAMS));
	assert!(exists<ContributionTracker>(@tidmat), error::not_found(ETRACKER_NOT_FOUND));
	let tracker = borrow_global_mut<ContributionTracker>(@tidmat);
	
	let c_idx = contrib_id - 1;
	let contrib_ref = vector::borrow_mut(&mut tracker.contributions, c_idx);
	let found = false;
 	if (campaign_id == contrib_ref.campaign_id) {
	    contrib_ref.status = status;
	    found = true;
	};
	assert!(found, error::not_found(ECONTRIBUTION_NOT_FOUND));
    }

    public fun accept_campaign_contributions(campaign_id: u64) acquires ContributionTracker {
	assert!(exists<ContributionTracker>(@tidmat), error::not_found(ETRACKER_NOT_FOUND));

	let tracker = borrow_global_mut<ContributionTracker>(@tidmat);
	let total_verified = 0;

	let i = 0;
	let len = vector::length<Contribution>(&tracker.contributions);
	
	while (i < len) {
	    let contribution_ref = vector::borrow_mut<Contribution>(&mut tracker.contributions, i);
	    if (contribution_ref.campaign_id == campaign_id && contribution_ref.status == CONTRIBUTION_STATUS_VERIFIED) {
	    	contribution_ref.status = CONTRIBUTION_STATUS_ACCEPTED;
	  	total_verified = total_verified + 1;
	    };
	    i = i + 1;
	};
	
	assert!(total_verified > 0, error::invalid_argument(EINVALID_CONTRIBUTION_PARAMS));
    }

    public fun submit_a_contribution(contributor: &signer, campaign_id: u64, data: vector<u8>) acquires ContributionTracker {
	assert!(vector::length(&data) > 0, error::invalid_argument(EINVALID_CONTRIBUTION_PARAMS));
	
	let contributions = get_contributions();
	let contributor_addr = signer::address_of(contributor);

	let i = 0;
	let len = vector::length(&contributions);
	while (i < len) {
	    let contribution_ref = vector::borrow(&contributions, i);
	    assert!(contribution_ref.campaign_id != campaign_id || contribution_ref.contributor != contributor_addr, error::already_exists(ECONTRIBUTION_ALREADY_EXISTS));
	    i = i + 1; 
	};	

	let contrib_id = next_contrib_id();
        let contrib = Contribution {
	    contribution_id: contrib_id,
	    campaign_id,
	    contributor: contributor_addr,
	    data,
	    status: CONTRIBUTION_STATUS_SUBMITTED
	};


	update_tracker_contributions(contrib);
	update_contrib_id(contrib_id);
    }

    public fun get_acceptable_contributions(contributions: vector<Contribution>): vector<Contribution> {
	let acceptable_contributions = vector::empty<Contribution>();

	let i = 0;
	let len = vector::length<Contribution>(&contributions);
        while (i < len) {
	    let contribution_ref = vector::borrow(&contributions, i);
	    if (contribution_ref.status == CONTRIBUTION_STATUS_ACCEPTED) {
	    	vector::push_back(&mut acceptable_contributions, *contribution_ref);
	    };
	    i = i + 1;
	};

	acceptable_contributions
    }
 
    public fun get_contribution_tracker(campaign_id: u64): (vector<Contribution>, vector<Contribution>) acquires ContributionTracker {
	assert!(exists<ContributionTracker>(@tidmat), error::not_found(ETRACKER_NOT_FOUND));

	let tracker = borrow_global<ContributionTracker>(@tidmat);

        let all_contributions = vector::empty<Contribution>();
        let verified_contributions = vector::empty<Contribution>();

	let i = 0;
   	let len = vector::length<Contribution>(&tracker.contributions);
	while (i < len) {
	    let contribution_ref = vector::borrow(&tracker.contributions, i);
	    if (contribution_ref.campaign_id == campaign_id) {    
		if (contribution_ref.status == CONTRIBUTION_STATUS_VERIFIED) {
		    vector::push_back(&mut verified_contributions, *contribution_ref);
	        } else {
		    vector::push_back(&mut all_contributions, *contribution_ref);
	        };
	    };
	    i = i + 1;
	};

	(all_contributions, verified_contributions)
    }
}
