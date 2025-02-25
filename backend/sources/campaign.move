module tidmat::campaign {
    use std::signer;
    use std::vector;
    use std::string::String;
    use aptos_std::math64;
    use aptos_std::simple_map::{Self, SimpleMap};
    use aptos_framework::timestamp;
    use aptos_framework::primary_fungible_store;
    use tidmat::escrow;
    use tidmat::treasury;
    use tidmat::contribution;

    // ========== Error Constants ==========
    const EINVALID_CAMPAIGN_PARAMS: u64 = 1;
    const ECAMPAIGN_NOT_FOUND: u64 = 2;
    const EUNAUTHORIZED_ACTION: u64 = 3;
    const ECAMPAIGN_EXPIRED: u64 = 4;
    const ECAMPAIGN_ALREADY_EXISTS: u64 = 5;
    const EREGISTRY_NOT_FOUND: u64 = 6;
    const ESTORE_NOT_FOUND: u64 = 7;
    const EINVALID_CONTRIBUTION_PARAMS: u64 = 8;
    const ECONTRIBUTION_NOT_FOUND: u64 = 9;
    const ENOT_ENOUGH_BAL: u64 = 10;

    // ========== Status Constants ==========
    const CAMPAIGN_STATUS_ACTIVE: u8 = 1;
    const CAMPAIGN_STATUS_COMPLETED: u8 = 2;
    const CAMPAIGN_STATUS_CANCELLED: u8 = 3;

    // ========== Fee Constants ==========
    const MAX_SERVICE_FEE_PERCENTAGE: u64 = 1;

    // ========== Status Getters ==========
    public fun get_status_active(): u8 { CAMPAIGN_STATUS_ACTIVE }
    public fun get_status_completed(): u8 { CAMPAIGN_STATUS_COMPLETED }
    public fun get_status_cancelled(): u8 { CAMPAIGN_STATUS_CANCELLED }

    // ========== Resource Structs ==========
    struct Campaign has key, store, drop {
        id: u64,
        name: String,
        creator: address,
        reward_pool: u64,
        escrow_c: escrow::Escrow,
        sample_data_hash: vector<u8>,
        data_type: vector<u8>,
        quality_threshold: u8,
        deadline: u64,
        min_contributions: u64,
        max_contributions: u64,
        status: u8,
        service_fee: u64,
    }

    struct CreatorCampaignStore has key {
        campaigns: SimpleMap<u64, Campaign>
    }

    struct CampaignRegistry has key {
        campaign_ids: vector<u64>,
        next_campaign_id: u64,
    }

    // ========== Module Initialization ==========
    // Initialize the campaign registry.
    fun init_module(admin: &signer) {
        init_module_internal(admin);
    }

    fun init_module_internal(admin: &signer) {
	move_to(admin, CampaignRegistry {
	    campaign_ids: vector::empty(),
	    next_campaign_id: 1,
	});
    }

    // Create a campaign store for a creator.
    fun create_campaign_store(creator: &signer) {
        move_to(creator, CreatorCampaignStore {
            campaigns: simple_map::new(),
        });
    }

    // ========== Campaign Management Functions ==========
    // Create a new campaign.
    public entry fun create_campaign(
        creator: &signer,
        name: String,
        reward_pool: u64,
        sample_data_hash: vector<u8>,
        data_type: vector<u8>,
        quality_threshold: u8,
        deadline: u64,
        min_contributions: u64,
        max_contributions: u64,
        service_fee: u64
    ) acquires CampaignRegistry, CreatorCampaignStore {
        let creator_addr = signer::address_of(creator);

        // Validate campaign parameters
        assert!(exists<CampaignRegistry>(@tidmat), EREGISTRY_NOT_FOUND);
        assert!(reward_pool > 0, EINVALID_CAMPAIGN_PARAMS);
        assert!(quality_threshold >= 50 && quality_threshold <= 80, EINVALID_CAMPAIGN_PARAMS);
        assert!(deadline > timestamp::now_seconds(), EINVALID_CAMPAIGN_PARAMS);
        assert!(min_contributions > 0 && min_contributions < max_contributions, EINVALID_CAMPAIGN_PARAMS);
        assert!(service_fee <= MAX_SERVICE_FEE_PERCENTAGE, EINVALID_CAMPAIGN_PARAMS);

	// Marketplace Cut
	let cut = math64::mul_div(reward_pool, service_fee, 100);
        let fa_metadata_object = treasury::get_fa_metadata();
	let creator_store_bal = primary_fungible_store::balance(creator_addr, fa_metadata_object);
	let total_amount = cut + reward_pool;	

        assert!(creator_store_bal >= total_amount, ENOT_ENOUGH_BAL);

	let creator_store = primary_fungible_store::primary_store(creator_addr, fa_metadata_object);

 	// Process fee payment
        treasury::process_payment(creator, creator_store, cut);
        
        // Create a campaign store if it doesn't exist
        if (!exists<CreatorCampaignStore>(creator_addr)) {
            create_campaign_store(creator);
        };

        // Get the campaign registry and store
        let registry = borrow_global_mut<CampaignRegistry>(@tidmat);
        let store = borrow_global_mut<CreatorCampaignStore>(creator_addr);

        // Generate a new campaign ID
        let campaign_id = registry.next_campaign_id;

        // Create an escrow for the campaign
        let esc = escrow::create_escrow(creator, campaign_id, reward_pool);

        // Create the campaign
        let campaign = Campaign {
            id: campaign_id,
            name,
            creator: creator_addr,
            reward_pool,
            escrow_c: esc,
            sample_data_hash,
            data_type,
            quality_threshold,
            deadline,
            min_contributions,
            max_contributions,
            status: CAMPAIGN_STATUS_ACTIVE,
            service_fee,
        };

        // Add the campaign to the registry and store
        simple_map::add(&mut store.campaigns, campaign_id, campaign);
        vector::push_back(&mut registry.campaign_ids, campaign_id);
        registry.next_campaign_id = campaign_id + 1;
    }

    // Cancel a campaign.
    public entry fun cancel_campaign(
        creator: &signer,
        campaign_id: u64
    ) acquires CreatorCampaignStore {
        let creator_addr = signer::address_of(creator);
        assert!(exists<CreatorCampaignStore>(creator_addr), ESTORE_NOT_FOUND);
        
        let store = borrow_global_mut<CreatorCampaignStore>(creator_addr);
       
        let campaign = simple_map::borrow_mut(&mut store.campaigns, &campaign_id); 
        assert!(campaign.id == campaign_id, ECAMPAIGN_NOT_FOUND);
        assert!(campaign.creator == creator_addr, EUNAUTHORIZED_ACTION);
        assert!(campaign.status == CAMPAIGN_STATUS_ACTIVE, EUNAUTHORIZED_ACTION);
        
        // Get verified contributions
        let (_, verified_contributions) = contribution::get_contribution_tracker(campaign.id);
        let total_verified = vector::length(&verified_contributions);

        // Refund based on the number of verified contributions
        if (total_verified >= campaign.min_contributions) {
            escrow::refund(creator, &mut campaign.escrow_c, true);
        } else {
            escrow::refund(creator, &mut campaign.escrow_c, false);
        };

        // Release funds if the escrow pool has a balance
        let pool_bal = escrow::get_escrow_pool_bal(&campaign.escrow_c);
	
        if (pool_bal > 0) {
            escrow::release_funds(creator, &mut campaign.escrow_c, verified_contributions, total_verified); 
        };

        // Update campaign status to cancelled
        campaign.status = CAMPAIGN_STATUS_CANCELLED;
    }

    // Finalize a campaign.
    public entry fun finalize_campaign(
        creator: &signer,
        campaign_id: u64
    ) acquires CreatorCampaignStore {
        let creator_addr = signer::address_of(creator);
        assert!(exists<CreatorCampaignStore>(creator_addr), ECAMPAIGN_NOT_FOUND);
        
        let store = borrow_global_mut<CreatorCampaignStore>(creator_addr);

        let campaign = simple_map::borrow_mut(&mut store.campaigns, &campaign_id);
        assert!(campaign.id == campaign_id, EINVALID_CAMPAIGN_PARAMS);
        assert!(campaign.creator == creator_addr, EUNAUTHORIZED_ACTION);
        
        // Get verified contributions
        let accepted_contributions = contribution::get_accepted_contributions(campaign.id);
        let total_accepted = vector::length(&accepted_contributions);
	
        // Release funds if the minimum contributions are met
        if (total_accepted >= campaign.min_contributions) {
            escrow::release_funds(creator, &mut campaign.escrow_c, accepted_contributions, total_accepted);
            campaign.status = CAMPAIGN_STATUS_COMPLETED;
        };
    }

    // ========== Contribution Management Functions ==========
    // Submit a contribution to a campaign.
    public entry fun submit_contribution(
        contributor: &signer,
	creator_addr: address,
        campaign_id: u64,
        data: vector<u8>
    ) acquires CreatorCampaignStore {
	assert!(!exceed_campaign_deadline(creator_addr, campaign_id), ECAMPAIGN_EXPIRED);
        contribution::submit_a_contribution(contributor, campaign_id, data);
    }

    // Update the status of a contribution.
    public entry fun update_contribution_status(
        _sender: &signer,
	creator_addr: address,
        campaign_id: u64,
        contributor_id: u64,
        status: u8
    ) acquires CreatorCampaignStore {
	assert!(!exceed_campaign_deadline(creator_addr, campaign_id), ECAMPAIGN_EXPIRED);
        contribution::update_contrib_status(status, contributor_id, campaign_id);
    }

    // Accept a single verified contribution by its ID
    public entry fun accept_single_contribution(creator: &signer,  contribution_id: u64) {
	let creator_addr = signer::address_of(creator);
	assert!(exists<CreatorCampaignStore>(creator_addr), ESTORE_NOT_FOUND);
	
	contribution::accept_a_contribution(contribution_id);
    }


    // Reject a single contribution by its ID
    public entry fun reject_single_contribution(creator: &signer, contribution_id: u64) {
	let creator_addr = signer::address_of(creator);
	assert!(exists<CreatorCampaignStore>(creator_addr), ESTORE_NOT_FOUND);

	contribution::reject_a_contribution(contribution_id);
    }


    // Accept verified contributions for a campaign.
    public entry fun accept_verified_contributions(
        creator: &signer,
        campaign_id: u64
    ) acquires CreatorCampaignStore {
        let creator_addr = signer::address_of(creator);
        assert!(exists<CreatorCampaignStore>(creator_addr), ESTORE_NOT_FOUND);

        let store = borrow_global<CreatorCampaignStore>(creator_addr);

        let campaign = simple_map::borrow(&store.campaigns, &campaign_id);
        assert!(campaign.id == campaign_id, ECAMPAIGN_NOT_FOUND);

        contribution::accept_campaign_contributions(campaign_id);
    }

    // ========== Query Functions ==========
    // Get all campaign IDs.
    #[view]
    public fun get_campaign_ids(): vector<u64> acquires CampaignRegistry {
        assert!(exists<CampaignRegistry>(@tidmat), EREGISTRY_NOT_FOUND);

        let registry = borrow_global<CampaignRegistry>(@tidmat);
        registry.campaign_ids
    }

    // Get campaign IDs for a specific creator.
    #[view]
    public fun get_creator_campaign_ids(creator_addr: address): vector<u64> acquires CreatorCampaignStore {
        assert!(exists<CreatorCampaignStore>(creator_addr), ESTORE_NOT_FOUND);
        
        let store = borrow_global<CreatorCampaignStore>(creator_addr);
        simple_map::keys(&store.campaigns)
    }

    // Get campaign details.
    #[view]
    public fun get_campaign_details(creator_addr: address, campaign_id: u64): (
        u64,
        String,
        address,
        u64,
        vector<u8>,
        vector<u8>,
        u8,
        u64,
        u64,
        u64,
        u8
    ) acquires CreatorCampaignStore {
        assert!(exists<CreatorCampaignStore>(creator_addr), ESTORE_NOT_FOUND);
        
        let store = borrow_global<CreatorCampaignStore>(creator_addr);

        let campaign = simple_map::borrow(&store.campaigns, &campaign_id);

        (
            campaign.id,
            campaign.name,
            campaign.creator,
            campaign.reward_pool,
            campaign.sample_data_hash,
            campaign.data_type,
            campaign.quality_threshold,
            campaign.deadline,
            campaign.min_contributions,
            campaign.max_contributions,
            campaign.status
        )
    }

    // Get the status of a campaign.
    #[view]
    public fun get_campaign_status(creator_addr: address, campaign_id: u64): u8 acquires CreatorCampaignStore {
        assert!(exists<CreatorCampaignStore>(creator_addr), ESTORE_NOT_FOUND);
        
        let store = borrow_global<CreatorCampaignStore>(creator_addr);
        
        let campaign = simple_map::borrow(&store.campaigns, &campaign_id);
        campaign.status
    }

    fun exceed_campaign_deadline(creator_addr: address, campaign_id: u64): bool acquires CreatorCampaignStore {
	let store = borrow_global<CreatorCampaignStore>(creator_addr);

	let campaign = simple_map::borrow(&store.campaigns, &campaign_id);
	if (timestamp::now_seconds() >= campaign.deadline) {
	    return true
	};

	return false
    }

    #[test_only]
    public fun init_module_for_test(aptos_framework: &signer, admin: &signer) {
	timestamp::set_time_has_started_for_testing(aptos_framework);

 	init_module_internal(admin);
    }
}
