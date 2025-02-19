module tidmat::campaign {
    use std::signer;
    use std::error;
    use std::vector;
    use std::string::String;
    use aptos_framework::timestamp;
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

    // ========== Status Constants ==========
    const CAMPAIGN_STATUS_DRAFT: u8 = 1;
    const CAMPAIGN_STATUS_ACTIVE: u8 = 2;
    const CAMPAIGN_STATUS_COMPLETED: u8 = 3;
    const CAMPAIGN_STATUS_CANCELLED: u8 = 4;

    // ========== Fee Constants ==========
    const SERVICE_FEE: u64 = 1;
    const CANCELLATION_FEE_PERCENTAGE: u8 = 10;
    const REFUND_PERCENTAGE_ON_CANCELLATION: u8 = 90;

    // ========== Resource Structs ==========
    struct Campaign has key, store, copy, drop {
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
        campaigns: vector<Campaign>,
    }

    struct CampaignRegistry has key {
        campaigns: vector<Campaign>,
        next_campaign_id: u64,
    }

    struct Fee has key {
        amount: u64,
        collector: address,
    }

    // ========== Module Initialization ==========
    /// Initialize the campaign registry.
    public fun initialize_registry(admin: &signer) {
        move_to(admin, CampaignRegistry {
            campaigns: vector::empty(),
            next_campaign_id: 1,
        });
    }

    /// Create a campaign store for a creator.
    fun create_campaign_store(creator: &signer) {
        move_to(creator, CreatorCampaignStore {
            campaigns: vector::empty(),
        });
    }

    // ========== Campaign Management Functions ==========
    /// Create a new campaign.
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
        assert!(exists<CampaignRegistry>(@tidmat), error::not_found(EREGISTRY_NOT_FOUND));
        assert!(reward_pool > 0, error::invalid_argument(EINVALID_CAMPAIGN_PARAMS));
        assert!(quality_threshold >= 50 && quality_threshold <= 80, error::invalid_argument(EINVALID_CAMPAIGN_PARAMS));
        assert!(deadline > timestamp::now_seconds(), error::invalid_argument(EINVALID_CAMPAIGN_PARAMS));
        assert!(min_contributions > 0 && min_contributions < max_contributions, error::invalid_argument(EINVALID_CAMPAIGN_PARAMS));
        assert!(service_fee <= SERVICE_FEE, error::invalid_argument(EINVALID_CAMPAIGN_PARAMS));

        // Charge creator for campaign creation
        treasury::process_payment(creator, service_fee);
        
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
        vector::push_back(&mut store.campaigns, campaign);
        vector::push_back(&mut registry.campaigns, campaign);
        registry.next_campaign_id = campaign_id + 1;
    }

    /// Cancel a campaign.
    public entry fun cancel_campaign(
        creator: &signer,
        campaign_id: u64
    ) acquires CreatorCampaignStore {
        let creator_addr = signer::address_of(creator);
        assert!(exists<CreatorCampaignStore>(creator_addr), error::not_found(ESTORE_NOT_FOUND));
        
        let store = borrow_global_mut<CreatorCampaignStore>(creator_addr);
        let c_idx = campaign_id - 1;

        let campaign = vector::borrow_mut(&mut store.campaigns, c_idx); 
        assert!(campaign.id == campaign_id, error::not_found(ECAMPAIGN_NOT_FOUND));
        assert!(campaign.creator == creator_addr, error::permission_denied(EUNAUTHORIZED_ACTION));
        assert!(campaign.status == CAMPAIGN_STATUS_ACTIVE, error::invalid_state(EUNAUTHORIZED_ACTION));
        
        // Get verified contributions
        let (_, verified_contributions) = contribution::get_contribution_tracker(campaign.id);
        let total_verified = vector::length(&verified_contributions);

        // Refund based on the number of verified contributions
        if (campaign.min_contributions >= total_verified) {
            escrow::refund(creator, campaign.escrow_c, true);
        } else {
            escrow::refund(creator, campaign.escrow_c, false);
        };

        // Release funds if the escrow pool has a balance
        let pool_bal = escrow::get_escrow_pool_bal(campaign.escrow_c);
        if (pool_bal > 0) {
            escrow::release_funds(creator, campaign.escrow_c, verified_contributions, total_verified); 
        };

        // Update campaign status to cancelled
        campaign.status = CAMPAIGN_STATUS_CANCELLED;
    }

    /// Finalize a campaign.
    public entry fun finalize_campaign(
        creator: &signer,
        campaign_id: u64
    ) acquires CreatorCampaignStore {
        let creator_addr = signer::address_of(creator);
        assert!(exists<CreatorCampaignStore>(creator_addr), error::not_found(ECAMPAIGN_NOT_FOUND));
        
        let store = borrow_global_mut<CreatorCampaignStore>(creator_addr);
        let c_idx = campaign_id - 1;

        let campaign = vector::borrow_mut(&mut store.campaigns, c_idx);
        assert!(campaign.id == campaign_id, error::invalid_argument(EINVALID_CAMPAIGN_PARAMS));
        assert!(campaign.creator == creator_addr, error::permission_denied(EUNAUTHORIZED_ACTION));
        assert!(timestamp::now_seconds() >= campaign.deadline, error::invalid_state(ECAMPAIGN_EXPIRED));
        
        // Get verified contributions
        let (_, verified_contributions) = contribution::get_contribution_tracker(campaign.id);
        let total_verified = vector::length(&verified_contributions);

        // Release funds if the minimum contributions are met
        if (total_verified >= campaign.min_contributions) {
            escrow::release_funds(creator, campaign.escrow_c, verified_contributions, total_verified);
            campaign.status = CAMPAIGN_STATUS_COMPLETED;
        };
    }

    // ========== Contribution Management Functions ==========
    /// Submit a contribution to a campaign.
    public entry fun submit_contribution(
        contributor: &signer,
        campaign_id: u64,
        data: vector<u8>
    ) {
        contribution::submit_a_contribution(contributor, campaign_id, data);
    }

    /// Update the status of a contribution.
    public entry fun update_contribution_status(
        _sender: &signer,
        campaign_id: u64,
        contributor_id: u64,
        status: u8
    ) {
        contribution::update_contrib_status(status, contributor_id, campaign_id);
    }

    /// Accept verified contributions for a campaign.
    public entry fun accept_verified_contributions(
        creator: &signer,
        campaign_id: u64
    ) acquires CreatorCampaignStore {
        let creator_addr = signer::address_of(creator);
        assert!(exists<CreatorCampaignStore>(creator_addr), error::not_found(ESTORE_NOT_FOUND));

        let store = borrow_global<CreatorCampaignStore>(creator_addr);
        let c_idx = campaign_id - 1;

        let campaign = vector::borrow(&store.campaigns, c_idx);
        assert!(campaign.id == campaign_id, error::not_found(ECAMPAIGN_NOT_FOUND));

        contribution::accept_campaign_contributions(campaign_id);
    }

    // ========== Query Functions ==========
    /// Get all campaign IDs.
    #[view]
    public fun get_campaign_ids(): vector<u64> acquires CampaignRegistry {
        assert!(exists<CampaignRegistry>(@tidmat), error::not_found(EREGISTRY_NOT_FOUND));

        let registry = borrow_global<CampaignRegistry>(@tidmat);
        let campaign_ids = vector::empty<u64>();
        let len = vector::length<Campaign>(&registry.campaigns);
        let i = 0;

        while (i < len) {
            let campaign_ref = vector::borrow(&registry.campaigns, i);
            vector::push_back(&mut campaign_ids, campaign_ref.id);
            i = i + 1;
        };

        campaign_ids
    }

    /// Get campaign IDs for a specific creator.
    #[view]
    public fun get_creator_campaign_ids(creator_addr: address): vector<u64> acquires CreatorCampaignStore {
        assert!(exists<CreatorCampaignStore>(creator_addr), error::not_found(ESTORE_NOT_FOUND));
        
        let store = borrow_global<CreatorCampaignStore>(creator_addr);
        let campaign_ids = vector::empty<u64>();
        let len = vector::length<Campaign>(&store.campaigns);
        let i = 0;

        while (i < len) {
            let campaign_ref = vector::borrow(&store.campaigns, i);
            vector::push_back(&mut campaign_ids, campaign_ref.id);
            i = i + 1;
        };

        campaign_ids
    }

    /// Get campaign details.
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
        assert!(exists<CreatorCampaignStore>(creator_addr), error::not_found(ESTORE_NOT_FOUND));
        
        let store = borrow_global<CreatorCampaignStore>(creator_addr);
        let c_idx = campaign_id - 1;

        let campaign = vector::borrow(&store.campaigns, c_idx);

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

    /// Get the status of a campaign.
    #[view]
    public fun get_campaign_status(creator_addr: address, campaign_id: u64): u8 acquires CreatorCampaignStore {
        assert!(exists<CreatorCampaignStore>(creator_addr), error::not_found(ESTORE_NOT_FOUND));
        
        let store = borrow_global<CreatorCampaignStore>(creator_addr);
        let c_idx = campaign_id - 1;

        let campaign = vector::borrow(&store.campaigns, c_idx);
        campaign.status
    }
}