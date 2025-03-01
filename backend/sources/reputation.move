module tidmat::reputation {
    use std::signer;
    use std::string::{Self, String};
    use std::vector;
    use aptos_framework::timestamp;

    /// Error codes 
    const EPROFILE_ALREADY_EXISTS: u64 = 1;
    const EPROFILE_NOT_FOUND: u64 = 2;
    const EBADGE_ALREADY_OWNED: u64 = 3;
    const EINVALID_SCORE_UPDATE: u64 = 4;
    const ENOT_AUTHORIZED: u64 = 5;
    const EINVALID_BADGE_TYPE: u64 = 6;

    /// Badge types
    const BADGE_NOVICE_CONTRIBUTOR: u8 = 1;
    const BADGE_EXPERIENCED_CONTRIBUTOR: u8 = 2;
    const BADGE_EXPERT_CONTRIBUTOR: u8 = 3;
    const BADGE_QUALITY_MASTER: u8 = 4;
    const BADGE_CONSISTENT_CONTRIBUTOR: u8 = 5;

    // ========== Badges Getters ==========
    public fun get_badge_novice(): u8 { BADGE_NOVICE_CONTRIBUTOR }
    public fun get_badge_experienced(): u8 { BADGE_EXPERIENCED_CONTRIBUTOR }
    public fun get_badge_expert(): u8 { BADGE_EXPERT_CONTRIBUTOR }
    public fun get_badge_quality(): u8 { BADGE_QUALITY_MASTER }
    public fun get_badge_consistent(): u8 { BADGE_CONSISTENT_CONTRIBUTOR }


    struct Badge has store, drop, copy {
        badge_type: u8,
        earned_at: u64,
        metadata: String
    }

    struct ContributorProfile has key {
        reputation_score: u64,
        quality_score: u64,
        total_contributions: u64,
        successful_contributions: u64,
        badges: vector<Badge>
    }

    struct ReputationConfig has key {
        admin: address,
        min_score_for_badges: vector<u64>,
        score_weights: vector<u64>
    }

    fun init_module(admin: &signer) {
	init_module_internal(admin);
    }

    fun init_module_internal(admin: &signer) {
	let min_scores = vector[
            5,   // Novice Contributor (Requires 5 total contributions)
            20,  // Experienced Contributor (Requires 20 successful contributions)
            1000, // Expert Contributor (Requires 1000 reputation points)
            95,  // Quality Master (Requires 95+ quality score)
            10   // Consistent Contributor (Requires 10 total contributions + 90% success rate)
        ];

        let score_weights = vector[
            10,  // +10 for each successful contribution
            5,   // Use as -5 for failed contribution
            20,  // +20 for dispute resolution in favor
            10,  // Use as -10 for late payments
            50   // +50 for high-quality contributions
        ];
	
        move_to(admin, ReputationConfig {
            admin: signer::address_of(admin),
            min_score_for_badges: min_scores,
            score_weights
        });
    }

    public entry fun create_profile(account: &signer) {
        let account_addr = signer::address_of(account);
        assert!(!exists<ContributorProfile>(account_addr), EPROFILE_ALREADY_EXISTS);

        let profile = ContributorProfile {
            reputation_score: 0,
            quality_score: 0,
            total_contributions: 0,
            successful_contributions: 0,
            badges: vector::empty()
        };

        move_to(account, profile);
    }

    public entry fun update_reputation(
        admin: &signer,
        contributor_address: address,
        score_change: u64,
        quality_change: u64
    ) acquires ContributorProfile, ReputationConfig {
        let config = borrow_global<ReputationConfig>(@tidmat);
        assert!(signer::address_of(admin) == config.admin, ENOT_AUTHORIZED);
        
        let profile = borrow_global_mut<ContributorProfile>(contributor_address);
        
        profile.reputation_score = profile.reputation_score + score_change;
        profile.quality_score = profile.quality_score + quality_change;

        check_and_award_badges(profile);
    }

    public fun record_contribution(
        contributor_address: address,
        was_successful: bool
    ) acquires ContributorProfile {
        let profile = borrow_global_mut<ContributorProfile>(contributor_address);
        if (was_successful) {
            profile.successful_contributions = profile.successful_contributions + 1;
        } else {
	    profile.total_contributions = profile.total_contributions + 1;
	};

        check_and_award_badges(profile);
    }

    public entry fun award_custom_badge(
        admin: &signer,
        contributor_address: address,
        badge_type: u8,
        metadata: String
    ) acquires ContributorProfile, ReputationConfig {
        let config = borrow_global<ReputationConfig>(@tidmat);
        assert!(signer::address_of(admin) == config.admin, ENOT_AUTHORIZED);
        assert!(badge_type <= BADGE_CONSISTENT_CONTRIBUTOR, EINVALID_BADGE_TYPE);
        
        let profile = borrow_global_mut<ContributorProfile>(contributor_address);
        award_badge(profile, badge_type, metadata);
    }

    #[view]
    public fun get_reputation_score(contributor_address: address): u64 acquires ContributorProfile {
        assert!(exists<ContributorProfile>(contributor_address), EPROFILE_NOT_FOUND);
        let profile = borrow_global<ContributorProfile>(contributor_address);
        profile.reputation_score
    }

    #[view]
    public fun get_quality_score(contributor_address: address): u64 acquires ContributorProfile {
        assert!(exists<ContributorProfile>(contributor_address), EPROFILE_NOT_FOUND);
        let profile = borrow_global<ContributorProfile>(contributor_address);
        profile.quality_score
    }

    #[view]
    public fun get_contribution_stats(contributor_address: address): (u64, u64) acquires ContributorProfile {
        assert!(exists<ContributorProfile>(contributor_address), EPROFILE_NOT_FOUND);
        let profile = borrow_global<ContributorProfile>(contributor_address);
        (profile.total_contributions, profile.successful_contributions)
    }

    #[view]
    public fun has_badge(contributor_address: address, badge_type: u8): bool acquires ContributorProfile {
        if (!exists<ContributorProfile>(contributor_address)) {
            return false
        };
        let profile = borrow_global<ContributorProfile>(contributor_address);
        has_badge_internal(profile, badge_type)
    }

    #[view]
    public fun get_all_badges(contributor_address: address): vector<Badge> acquires ContributorProfile {
        assert!(exists<ContributorProfile>(contributor_address), EPROFILE_NOT_FOUND);
        let profile = borrow_global<ContributorProfile>(contributor_address);
        profile.badges
    }

    fun has_badge_internal(profile: &ContributorProfile, badge_type: u8): bool {
        let i = 0;
        let len = vector::length(&profile.badges);
        while (i < len) {
            if (vector::borrow(&profile.badges, i).badge_type == badge_type) {
                return true
            };
            i = i + 1;
        };
        false
    }

    fun check_and_award_badges(profile: &mut ContributorProfile) {
        // Check for Novice badge
        if (!has_badge_internal(profile, BADGE_NOVICE_CONTRIBUTOR) && 
            profile.total_contributions >= 5) {
            award_badge(profile, BADGE_NOVICE_CONTRIBUTOR, string::utf8(b"Completed 5 contributions"));
        };

        // Check for Experienced badge
        if (!has_badge_internal(profile, BADGE_EXPERIENCED_CONTRIBUTOR) && 
            profile.successful_contributions >= 20) {
            award_badge(profile, BADGE_EXPERIENCED_CONTRIBUTOR, string::utf8(b"Completed 20 successful contributions"));
        };

        // Check for Expert badge
        if (!has_badge_internal(profile, BADGE_EXPERT_CONTRIBUTOR) && 
            profile.reputation_score >= 1000) {
            award_badge(profile, BADGE_EXPERT_CONTRIBUTOR, string::utf8(b"Achieved 1000 reputation points"));
        };

        // Check for Quality Master badge
        if (!has_badge_internal(profile, BADGE_QUALITY_MASTER) && 
            profile.quality_score >= 95) {
            award_badge(profile, BADGE_QUALITY_MASTER, string::utf8(b"Maintained 95+ quality score"));
        };

        // Check for Consistent Contributor badge
        if (!has_badge_internal(profile, BADGE_CONSISTENT_CONTRIBUTOR) && 
            profile.total_contributions >= 10 &&
            (profile.successful_contributions * 100 / profile.total_contributions) >= 90) {
            award_badge(profile, BADGE_CONSISTENT_CONTRIBUTOR, string::utf8(b"90% success rate on contributions"));
        };
    }

    fun award_badge(profile: &mut ContributorProfile, badge_type: u8, metadata: String) {
        if (!has_badge_internal(profile, badge_type)) {
            let badge = Badge {
                badge_type,
                earned_at: timestamp::now_seconds(),
                metadata
            };
            vector::push_back(&mut profile.badges, badge);
        }
    }

    public fun profile_exists(contributor_addr: address): bool {
	exists<ContributorProfile>(contributor_addr)
    }

    #[test_only]
    public fun init_module_for_test(aptos_framework: &signer, admin: &signer) {
	timestamp::set_time_has_started_for_testing(aptos_framework);

 	init_module_internal(admin);
    }
}
