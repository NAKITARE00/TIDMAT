module backend::CampaignCreation {
    use std::signer;
    use std::vector;

    struct Campaign has key, store {
        creator: address,
        data_type: vector<u8>, // Data type description
        reward_pool: u64, // Total tokens allocated
        min_quality: u8, // Minimum quality score required
    }

    public entry fun create_campaign(
        account: &signer,
        data_type: vector<u8>,
        reward_pool: u64,
        min_quality: u8
    ) {
        let creator = signer::address_of(account);
        let campaign = Campaign { creator, data_type, reward_pool, min_quality };

        move_to(account, campaign);
    }
}
