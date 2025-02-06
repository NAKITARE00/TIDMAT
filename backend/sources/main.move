module backend::CampaignCreation {
    use std::signer;
    use std::vector;
    use std::timestamp;
    
    struct Campaign has key, store {
        creator: address,
        data_type: vector<u8>, // Data type description
        reward_pool: u64, // Total tokens allocated
        min_quality: u8, // Minimum quality score required
        start_time: u64, // Timestamp when campaign is created
        duration: u64, // Duration in seconds
        is_active: bool, // Campaign status
    }
    
    public entry fun create_campaign(
        account: &signer,
        data_type: vector<u8>,
        reward_pool: u64,
        min_quality: u8,
        duration: u64 // Duration in seconds
    ) {
        let creator = signer::address_of(account);
        let start_time = timestamp::now_seconds();
        let campaign = Campaign { 
            creator, 
            data_type, 
            reward_pool, 
            min_quality, 
            start_time, 
            duration, 
            is_active: true 
        };

        move_to(account, campaign);
    }
    
    public entry fun close_campaign(account: &signer) acquires Campaign {
        let creator = signer::address_of(account);
        let campaign_ref = borrow_global_mut<Campaign>(creator);
        
        assert!(campaign_ref.is_active, 100);
        campaign_ref.is_active = false;
    }
    
    public fun is_campaign_expired(creator: address): bool acquires Campaign {
        let campaign_ref = borrow_global<Campaign>(creator);
        let current_time: u64 = timestamp::now_seconds();
    
        current_time >= campaign_ref.start_time + campaign_ref.duration
    }   
}