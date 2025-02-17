module tidmat::campaign_tests {
    use std::signer;
    use std::vector;
    use std::string;
    use std::error;
    use tidmat::campaign;
    use tidmat::escrow;
    use tidmat::treasury;
    use tidmat::contribution;

    public entry fun test_initialize_registry(admin: &signer) {
        campaign::initialize_registry(admin);
        let campaign_ids = campaign::get_campaign_ids();
        assert!(vector::length(&campaign_ids) == 0, error::not_found(1));
    }

    public entry fun test_create_campaign(creator: &signer) {
        let name = string::utf8(b"Test Campaign");
        let reward_pool = 1000;
        let sample_data_hash = vector::empty<u8>();
        let data_type = vector::empty<u8>();
        let quality_threshold = 60;
        let deadline = 9999999999;
        let min_contributions = 5;
        let max_contributions = 10;
        let service_fee = 1;
        
        campaign::create_campaign(
            creator,
            name,
            reward_pool,
            sample_data_hash,
            data_type,
            quality_threshold,
            deadline,
            min_contributions,
            max_contributions,
            service_fee
        );

        let campaign_ids = campaign::get_creator_campaign_ids(signer::address_of(creator));
        assert!(vector::length(&campaign_ids) == 1, error::invalid_argument(2));
    }

    public entry fun test_cancel_campaign(creator: &signer) {
        let campaign_ids = campaign::get_creator_campaign_ids(signer::address_of(creator));
        assert!(vector::length(&campaign_ids) > 0, error::not_found(3));
        
        let campaign_id = vector::borrow(&campaign_ids, 0);
        campaign::cancel_campaign(creator, *campaign_id);
        
        let status = campaign::get_campaign_status(signer::address_of(creator), *campaign_id);
        assert!(status == 4, error::invalid_argument(4)); // 4 is CAMPAIGN_STATUS_CANCELLED
    }

    public entry fun test_finalize_campaign(creator: &signer) {
        let campaign_ids = campaign::get_creator_campaign_ids(signer::address_of(creator));
        assert!(vector::length(&campaign_ids) > 0, error::not_found(5));
        
        let campaign_id = vector::borrow(&campaign_ids, 0);
        campaign::finalize_campaign(creator, *campaign_id);
        
        let status = campaign::get_campaign_status(signer::address_of(creator), *campaign_id);
        assert!(status == 3, error::invalid_argument(6)); // 3 is CAMPAIGN_STATUS_COMPLETED
    }

    public entry fun test_get_campaign_details(creator: &signer) {
        let campaign_ids = campaign::get_creator_campaign_ids(signer::address_of(creator));
        assert!(vector::length(&campaign_ids) > 0, error::not_found(7));
        
        let campaign_id = vector::borrow(&campaign_ids, 0);
        let (id, _, _, _, _, _, _, _, _, _, _) = campaign::get_campaign_details(signer::address_of(creator), *campaign_id);
        
        assert!(id == *campaign_id, error::invalid_argument(8));
    }
}