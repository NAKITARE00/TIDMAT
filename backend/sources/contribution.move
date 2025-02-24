module tidmat::contribution {
    use std::signer;
    use std::error;
    use std::vector;
    use aptos_framework::timestamp;

    // ========== Error Constants ==========
    const ECONTRIBUTION_ALREADY_EXISTS: u64 = 1;
    const ECONTRIBUTION_NOT_FOUND: u64 = 2;
    const EINVALID_CONTRIBUTION_PARAMS: u64 = 3;
    const EUNAUTHORIZED_ACTION: u64 = 4;
    const ECAMPAIGN_NOT_FOUND: u64 = 5;
    const ETRACKER_NOT_FOUND: u64 = 6;

    // ========== Status Constants ==========
    const CONTRIBUTION_STATUS_SUBMITTED: u8 = 1;
    const CONTRIBUTION_STATUS_VERIFIED: u8 = 2;
    const CONTRIBUTION_STATUS_ACCEPTED: u8 = 3;
    const CONTRIBUTION_STATUS_REJECTED: u8 = 4;

    // ========== Resource Structs ==========
    struct Contribution has key, store, copy, drop {
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

    // ========== Status Getters ==========
    public fun get_status_submitted(): u8 { CONTRIBUTION_STATUS_SUBMITTED }
    public fun get_status_verified(): u8 { CONTRIBUTION_STATUS_VERIFIED }
    public fun get_status_accepted(): u8 { CONTRIBUTION_STATUS_ACCEPTED }
    public fun get_status_rejected(): u8 { CONTRIBUTION_STATUS_REJECTED }

    // ========== Module Initialization ==========
    /// Initialize the contribution module for the given admin account
    fun init_module(admin: &signer) {
        init_module_internal(admin);
    }

    fun init_module_internal(admin: &signer) {
	move_to(admin, ContributionTracker {
	    contributions: vector::empty<Contribution>(),
	    next_contribution_id: 1,
	});
    }

    // ========== Contribution Management Functions ==========
    /// Submit a new contribution to a campaign
    public fun submit_a_contribution(
        contributor: &signer,
        campaign_id: u64,
        data: vector<u8>
    ) acquires ContributionTracker {
        assert!(vector::length(&data) > 0, error::invalid_argument(EINVALID_CONTRIBUTION_PARAMS));

        let tracker_ref = borrow_global_mut<ContributionTracker>(@tidmat);
        let contributor_addr = signer::address_of(contributor);

        assert!(
            !contribution_exists_for_campaign_and_contributor(&tracker_ref.contributions, campaign_id, contributor_addr),
            error::already_exists(ECONTRIBUTION_ALREADY_EXISTS)
        );

        let contrib_id = tracker_ref.next_contribution_id;
        let contrib = Contribution {
            contribution_id: contrib_id,
            campaign_id,
            contributor: contributor_addr,
            data,
            status: CONTRIBUTION_STATUS_SUBMITTED,
        };

        vector::push_back(&mut tracker_ref.contributions, contrib);
        tracker_ref.next_contribution_id = tracker_ref.next_contribution_id + 1;
    }

    /// Update the status of a contribution
    public fun update_contrib_status(
        status: u8,
        contrib_id: u64,
        campaign_id: u64
    ) acquires ContributionTracker {
        assert!(
            status == CONTRIBUTION_STATUS_VERIFIED || status == CONTRIBUTION_STATUS_REJECTED,
            error::invalid_argument(EINVALID_CONTRIBUTION_PARAMS)
        );

        let tracker = borrow_global_mut<ContributionTracker>(@tidmat);
        let c_idx = contrib_id - 1;

        assert!(c_idx < vector::length(&tracker.contributions), error::not_found(ECONTRIBUTION_NOT_FOUND));

        let contrib_ref = vector::borrow_mut(&mut tracker.contributions, c_idx);
        assert!(contrib_ref.campaign_id == campaign_id, error::not_found(ECONTRIBUTION_NOT_FOUND));
        contrib_ref.status = status;
    }
	
    // Accept a verified contribution
    public fun accept_a_contribution(contribution_id: u64) acquires ContributionTracker {
	let tracker = borrow_global_mut<ContributionTracker>(@tidmat);

	let c_idx = contribution_id - 1;
	let contrib_ref = vector::borrow_mut(&mut tracker.contributions, c_idx);
	
	if (contrib_ref.status == get_status_verified()) {
	    contrib_ref.status = get_status_accepted();
	};
	
    }

    // Reject a contribution
    public fun reject_a_contribution(contribution_id: u64) acquires ContributionTracker {
	let tracker = borrow_global_mut<ContributionTracker>(@tidmat);
	
	let c_idx = contribution_id - 1;
	let contrib_ref = vector::borrow_mut(&mut tracker.contributions, c_idx);
	contrib_ref.status = get_status_rejected();
    }



    /// Accept all verified contributions for a campaign
    public fun accept_campaign_contributions(campaign_id: u64) acquires ContributionTracker {
        let tracker = borrow_global_mut<ContributionTracker>(@tidmat);
        let total_accepted = 0;
        let len = vector::length(&tracker.contributions);
        let i = 0;

        while (i < len) {
            let contribution_ref = vector::borrow_mut(&mut tracker.contributions, i);
            if (contribution_ref.campaign_id == campaign_id && contribution_ref.status == CONTRIBUTION_STATUS_VERIFIED) {
                contribution_ref.status = CONTRIBUTION_STATUS_ACCEPTED;
                total_accepted = total_accepted + 1;
            };
            i = i + 1;
        };

        assert!(total_accepted > 0, error::invalid_argument(EINVALID_CONTRIBUTION_PARAMS));
    }

    // ========== Query Functions ==========
    /// Get all contribution IDs for a specific campaign
    public fun get_campaign_contributions(campaign_id: u64): vector<u64> acquires ContributionTracker {
        let tracker = borrow_global<ContributionTracker>(@tidmat);
        let contributions = vector::empty<u64>();
        let len = vector::length(&tracker.contributions);
        let i = 0;

        while (i < len) {
            let contribution_ref = vector::borrow(&tracker.contributions, i);
            if (contribution_ref.campaign_id == campaign_id) {
                vector::push_back(&mut contributions, contribution_ref.contribution_id);
            };
            i = i + 1;
        };

        contributions
    }

    /// Get details for a specific contributor
    public fun get_contributor_details(contributor_id: u64): (u64, address, vector<u8>, u8) 
    acquires ContributionTracker {
        let tracker = borrow_global<ContributionTracker>(@tidmat);
        let c_idx = contributor_id - 1;

        assert!(c_idx < vector::length(&tracker.contributions), error::not_found(ECONTRIBUTION_NOT_FOUND));

        let contribution_ref = vector::borrow(&tracker.contributions, c_idx);
        (
            contribution_ref.campaign_id,
            contribution_ref.contributor,
            contribution_ref.data,
            contribution_ref.status
        )
    }

    public fun get_accepted_contributions(campaign_id: u64): vector<Contribution> acquires ContributionTracker {
	let tracker = borrow_global<ContributionTracker>(@tidmat);
	let acc = vector::empty<Contribution>();
	
	let i = 0;
	let len = vector::length(&tracker.contributions);
	while (i < len) {
	   let contribution_ref = vector::borrow(&tracker.contributions, i);
	   if (contribution_ref.campaign_id == campaign_id && contribution_ref.status == CONTRIBUTION_STATUS_ACCEPTED) {
		vector::push_back(&mut acc, *contribution_ref);
	   };
	   i = i + 1;
	};

	acc
    }

    /// Get contribution statistics for a campaign
    public fun get_contribution_tracker(campaign_id: u64): (u64, vector<Contribution>) acquires ContributionTracker {
        let tracker = borrow_global<ContributionTracker>(@tidmat);
        let total_contributions = 0;
        let verified_contributions = vector::empty<Contribution>();
        let len = vector::length(&tracker.contributions);
        let i = 0;

        while (i < len) {
            let contribution_ref = vector::borrow(&tracker.contributions, i);
            if (contribution_ref.campaign_id == campaign_id) {
                total_contributions = total_contributions + 1;
                if (contribution_ref.status == CONTRIBUTION_STATUS_VERIFIED) {
                    vector::push_back(&mut verified_contributions, *contribution_ref);
                }
            };
            i = i + 1;
        };

        (total_contributions, verified_contributions)
    }

    /// Get contributor address from a Contribution
    public fun get_contributor_addr(contribution: &Contribution): address {
        contribution.contributor
    }

    /// Check if contribution tracker exists for an address
    public fun contribution_tracker_exists(addr: address): bool {
        exists<ContributionTracker>(addr)
    }

    // ========== Helper Functions ==========
    /// Check if a contribution exists for a campaign and contributor
    fun contribution_exists_for_campaign_and_contributor(
        contributions: &vector<Contribution>,
        campaign_id: u64,
        contributor_addr: address
    ): bool {
        let len = vector::length(contributions);
        let i = 0;

        while (i < len) {
            let contribution_ref = vector::borrow(contributions, i);
            if (contribution_ref.campaign_id == campaign_id && contribution_ref.contributor == contributor_addr) {
                return true
            };
            i = i + 1;
        };
        false
    }

    #[test_only]
    public fun init_module_for_test(aptos_framework: &signer, admin: &signer) {
	timestamp::set_time_has_started_for_testing(aptos_framework);

	init_module_internal(admin);
    }
}
