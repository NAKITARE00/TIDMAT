module tidmat::reputation_test {
    use std::signer;
    use std::string::{String, Self};
    use tidmat::reputation;
    use aptos_framework::timestamp;

    /// Test initializing the reputation system
    public entry fun test_initialize_reputation_system(admin: &signer) {
        let min_scores = vector[5, 20, 1000, 95, 10];
        let score_weights = vector[1, 2, 3];
        reputation::initialize_reputation_system(admin, min_scores, score_weights);
    }

    /// Test creating a contributor profile
    public entry fun test_create_profile(user: &signer) {
        reputation::create_profile(user);
    }

    /// Test updating reputation scores
    public entry fun test_update_reputation(admin: &signer, user: &signer) {
        let user_addr = signer::address_of(user);
        reputation::update_reputation(admin, user_addr, 50, 10);
    }

    /// Test recording a contribution
    public entry fun test_record_contribution(user: &signer) {
        let user_addr = signer::address_of(user);
        reputation::record_contribution(user_addr, true);
    }

    /// Test awarding a custom badge
    public entry fun test_award_custom_badge(admin: &signer, user: &signer) {
        let user_addr = signer::address_of(user);
        let badge_type = 3; // Expert Contributor
        let metadata = string::utf8(b"Custom badge awarded");
        reputation::award_custom_badge(admin, user_addr, badge_type, metadata);
    }

    /// Test retrieving reputation score
    #[view]
    public fun test_get_reputation_score(user_addr: address): u64 {
        reputation::get_reputation_score(user_addr)
    }

    /// Test retrieving quality score
    #[view]
    public fun test_get_quality_score(user_addr: address): u64 {
        reputation::get_quality_score(user_addr)
    }

    /// Test retrieving contribution statistics
    #[view]
    public fun test_get_contribution_stats(user_addr: address): (u64, u64) {
        reputation::get_contribution_stats(user_addr)
    }

    /// Test checking if a user has a badge
    #[view]
    public fun test_has_badge(user_addr: address, badge_type: u8): bool {
        reputation::has_badge(user_addr, badge_type)
    }

    /// Test retrieving all badges of a user
    #[view]
    public fun test_get_all_badges(user_addr: address): vector<reputation::Badge> {
        reputation::get_all_badges(user_addr)
    }
}
