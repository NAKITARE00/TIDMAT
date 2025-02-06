module tidmat::campaign {
    use std::signer;
    use std::error;
    use std::vector;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::timestamp;
    use aptos_framework::event;
    use aptos_framework::account;
    use tidmat::escrow;
    use tidmat::contribution;

    /// Error codes
    const EINVALID_CAMPAIGN_PARAMS: u64 = 1;
    const ECAMPAIGN_NOT_FOUND: u64 = 2;
    const EUNAUTHORIZED_ACTION: u64 = 3;
    const ECAMPAIGN_EXPIRED: u64 = 4;
    const ECAMPAIGN_ALREADY_EXISTS: u64 = 5;

    /// Campaign status constants
    const CAMPAIGN_STATUS_DRAFT: u8 = 1;
    const CAMPAIGN_STATUS_ACTIVE: u8 = 2;
    const CAMPAIGN_STATUS_COMPLETED: u8 = 3;
    const CAMPAIGN_STATUS_CANCELLED: u8 = 4;

    /// Campaign events
    struct CampaignEvent has drop, store {
        campaign_id: u64,
        creator: address,
        action: u8, // 1: created, 2: activated, 3: completed, 4: cancelled
        timestamp: u64
    }

    struct Campaign has key {
        id: u64,
        creator: address,
        total_reward_pool: u64,
        remaining_rewards: u64,
        data_type: vector<u8>,
        quality_threshold: u8,
        deadline: u64,
        min_contributions: u64,
        max_contributions: u64,
        status: u8,
        service_fee_percentage: u8,
        campaign_events: event::EventHandle<CampaignEvent>
    }

    public entry fun create_campaign<CoinType>(
        creator: &signer,
        total_reward_pool: u64,
        data_type: vector<u8>,
        quality_threshold: u8,
        deadline: u64,
        min_contributions: u64,
        max_contributions: u64,
        service_fee_percentage: u8
    ) {
        let creator_addr = signer::address_of(creator);
        
        assert!(total_reward_pool > 0, error::invalid_argument(EINVALID_CAMPAIGN_PARAMS));
        assert!(quality_threshold >= 50 && quality_threshold <= 80, error::invalid_argument(EINVALID_CAMPAIGN_PARAMS));
        assert!(deadline > timestamp::now_seconds(), error::invalid_argument(EINVALID_CAMPAIGN_PARAMS));
        assert!(min_contributions > 0 && min_contributions < max_contributions, error::invalid_argument(EINVALID_CAMPAIGN_PARAMS));
        assert!(service_fee_percentage <= 20, error::invalid_argument(EINVALID_CAMPAIGN_PARAMS));
        
        let campaign_id = timestamp::now_seconds();
        
        escrow::create_escrow<CoinType>(
            creator, 
            creator_addr, 
            total_reward_pool
        );

        let campaign = Campaign {
            id: campaign_id,
            creator: creator_addr,
            total_reward_pool,
            remaining_rewards: total_reward_pool,
            data_type,
            quality_threshold,
            deadline,
            min_contributions,
            max_contributions,
            status: CAMPAIGN_STATUS_ACTIVE,
            service_fee_percentage,
            campaign_events: account::new_event_handle<CampaignEvent>(creator)
        };

        contribution::create_contribution_tracker(
            creator, 
            quality_threshold
        );

        event::emit_event(&mut campaign.campaign_events, CampaignEvent {
            campaign_id,
            creator: creator_addr,
            action: 1,
            timestamp: timestamp::now_seconds()
        });

        move_to(creator, campaign);
    }

    public entry fun cancel_campaign<CoinType>(
        creator: &signer,
        campaign_id: u64
    ) acquires Campaign {
        let creator_addr = signer::address_of(creator);
        assert!(exists<Campaign>(creator_addr), error::not_found(ECAMPAIGN_NOT_FOUND));
        
        let campaign = borrow_global_mut<Campaign>(creator_addr);
        assert!(campaign.id == campaign_id, error::invalid_argument(EINVALID_CAMPAIGN_PARAMS));
        assert!(campaign.creator == creator_addr, error::permission_denied(EUNAUTHORIZED_ACTION));
        assert!(campaign.status == CAMPAIGN_STATUS_ACTIVE, error::invalid_state(EUNAUTHORIZED_ACTION));
        
        campaign.status = CAMPAIGN_STATUS_CANCELLED;
        
        if (campaign.remaining_rewards > 0) {
            escrow::refund<CoinType>(creator, creator_addr);
        };

        event::emit_event(&mut campaign.campaign_events, CampaignEvent {
            campaign_id,
            creator: creator_addr,
            action: 4,
            timestamp: timestamp::now_seconds()
        });
    }

    public entry fun finalize_campaign<CoinType>(
        creator: &signer,
        campaign_id: u64
    ) acquires Campaign {
        let creator_addr = signer::address_of(creator);
        assert!(exists<Campaign>(creator_addr), error::not_found(ECAMPAIGN_NOT_FOUND));
        
        let campaign = borrow_global_mut<Campaign>(creator_addr);
        assert!(campaign.id == campaign_id, error::invalid_argument(EINVALID_CAMPAIGN_PARAMS));
        assert!(campaign.creator == creator_addr, error::permission_denied(EUNAUTHORIZED_ACTION));
        assert!(timestamp::now_seconds() >= campaign.deadline, error::invalid_state(ECAMPAIGN_EXPIRED));
        
        let (total_contributions, verified_contributions, _) = 
            contribution::get_contribution_tracker(creator_addr);
        
        if (verified_contributions >= campaign.min_contributions) {
            campaign.status = CAMPAIGN_STATUS_COMPLETED;
            
            event::emit_event(&mut campaign.campaign_events, CampaignEvent {
                campaign_id,
                creator: creator_addr,
                action: 3,
                timestamp: timestamp::now_seconds()
            });
        } else {
            campaign.status = CAMPAIGN_STATUS_CANCELLED;
            escrow::refund<CoinType>(creator, creator_addr);
            
            event::emit_event(&mut campaign.campaign_events, CampaignEvent {
                campaign_id,
                creator: creator_addr,
                action: 4,
                timestamp: timestamp::now_seconds()
            });
        };
    }

    #[view]
    public fun get_campaign_details(creator_addr: address): (u64, address, u64, u64, u8, u64, u8) acquires Campaign {
        let campaign = borrow_global<Campaign>(creator_addr);
        (
            campaign.id,
            campaign.creator,
            campaign.total_reward_pool,
            campaign.remaining_rewards,
            campaign.quality_threshold,
            campaign.deadline,
            campaign.status
        )
    }

    #[view]
    public fun get_campaign_status(creator_addr: address): u8 acquires Campaign {
        let campaign = borrow_global<Campaign>(creator_addr);
        campaign.status
    }
}
