#[test_only]
module tidmat::reputation_tests {
    use std::signer;
    use std::string;
    use aptos_framework::timestamp;
    use tidmat::reputation;

    // Test accounts
    const ADMIN: address = @tidmat;
    const ALICE: address = @0x123;
    const BOB: address = @0x456;
    const CHARLIE: address = @0x789;

    // Test setup helper function
    fun setup(aptos_framework: &signer, admin: &signer, alice: &signer, bob: &signer) {
        // Initialize the module
        reputation::init_module_for_test(aptos_framework, admin);
        
        // Set timestamp for badge timestamps
        timestamp::update_global_time_for_test_secs(1000);
        
        // Create profiles for test users
        reputation::create_profile(alice);
        reputation::create_profile(bob);
    }

    #[test(aptos_framework = @std, admin = @tidmat, alice = @0x123, bob = @0x456)]
    fun test_create_profile_success(aptos_framework: &signer, admin: &signer, alice: &signer, bob: &signer) {
        // Setup the test environment
        reputation::init_module_for_test(aptos_framework, admin);
        
        // Create a profile
        reputation::create_profile(alice);
        
        // Check that the profile exists
        assert!(reputation::profile_exists(signer::address_of(alice)), 0);
        
        // Check initial reputation and quality scores
        assert!(reputation::get_reputation_score(signer::address_of(alice)) == 0, 0);
        assert!(reputation::get_quality_score(signer::address_of(alice)) == 0, 0);
        
        // Check initial contribution stats
        let (total, successful) = reputation::get_contribution_stats(signer::address_of(alice));
        assert!(total == 0, 0);
        assert!(successful == 0, 0);
        
        // Check that no badges are awarded yet
        let badges = reputation::get_all_badges(signer::address_of(alice));
        assert!(std::vector::length(&badges) == 0, 0);
    }

    #[test(aptos_framework = @std, admin = @tidmat, alice = @0x123)]
    #[expected_failure(abort_code = reputation::EPROFILE_ALREADY_EXISTS)]
    fun test_create_profile_already_exists(aptos_framework: &signer, admin: &signer, alice: &signer) {
        reputation::init_module_for_test(aptos_framework, admin);
        
        // Create a profile
        reputation::create_profile(alice);
        
        // Try to create another profile for the same user
        reputation::create_profile(alice); // This should fail
    }

    #[test(aptos_framework = @std, admin = @tidmat, alice = @0x123, bob = @0x456)]
    fun test_update_reputation(aptos_framework: &signer, admin: &signer, alice: &signer, bob: &signer) {
        setup(aptos_framework, admin, alice, bob);
        
        let alice_addr = signer::address_of(alice);
        
        // Update reputation and quality scores
        reputation::update_reputation(admin, alice_addr, 100, 50);
        
        // Check that scores were updated
        assert!(reputation::get_reputation_score(alice_addr) == 100, 0);
        assert!(reputation::get_quality_score(alice_addr) == 50, 0);
    }

    #[test(aptos_framework = @std, admin = @tidmat, alice = @0x123, bob = @0x456)]
    #[expected_failure(abort_code = reputation::ENOT_AUTHORIZED)]
    fun test_update_reputation_unauthorized(aptos_framework: &signer, admin: &signer, alice: &signer, bob: &signer) {
        setup(aptos_framework, admin, alice, bob);
        
        let alice_addr = signer::address_of(alice);
        
        // Bob tries to update Alice's reputation (should fail)
        reputation::update_reputation(bob, alice_addr, 100, 50);
    }

    #[test(aptos_framework = @std, admin = @tidmat, alice = @0x123, bob = @0x456)]
    fun test_record_contribution(aptos_framework: &signer, admin: &signer, alice: &signer, bob: &signer) {
        setup(aptos_framework, admin, alice, bob);
        
        let alice_addr = signer::address_of(alice);
        
        // Record successful contribution
        reputation::record_contribution(alice_addr, true);
        
        // Check stats
        let (total, successful) = reputation::get_contribution_stats(alice_addr);
        assert!(successful == 1, 0);
        
        // Record unsuccessful contribution
        reputation::record_contribution(alice_addr, false);
        
        // Check updated stats
        let (total, successful) = reputation::get_contribution_stats(alice_addr);
        assert!(total == 1, 0);
        assert!(successful == 1, 0);
    }

    #[test(aptos_framework = @std, admin = @tidmat, alice = @0x123, bob = @0x456)]
    fun test_award_custom_badge(aptos_framework: &signer, admin: &signer, alice: &signer, bob: &signer) {
        setup(aptos_framework, admin, alice, bob);
        
        let alice_addr = signer::address_of(alice);
        let metadata = string::utf8(b"Special contributor award");
        
        // Award a custom badge
        reputation::award_custom_badge(admin, alice_addr, reputation::get_badge_novice(), metadata);
        
        // Check that the badge was awarded
        assert!(reputation::has_badge(alice_addr, reputation::get_badge_novice()), 0);
        
        // Check the badge details
        let badges = reputation::get_all_badges(alice_addr);
        assert!(std::vector::length(&badges) == 1, 0);
    }

    #[test(aptos_framework = @std, admin = @tidmat, alice = @0x123, bob = @0x456)]
    #[expected_failure(abort_code = reputation::ENOT_AUTHORIZED)]
    fun test_award_custom_badge_unauthorized(aptos_framework: &signer, admin: &signer, alice: &signer, bob: &signer) {
        setup(aptos_framework, admin, alice, bob);
        
        let alice_addr = signer::address_of(alice);
        let metadata = string::utf8(b"Unauthorized badge");
        
        // Bob tries to award a badge (should fail)
        reputation::award_custom_badge(bob, alice_addr, reputation::get_badge_novice(), metadata);
    }

    #[test(aptos_framework = @std, admin = @tidmat, alice = @0x123, bob = @0x456)]
    #[expected_failure(abort_code = reputation::EINVALID_BADGE_TYPE)]
    fun test_award_invalid_badge_type(aptos_framework: &signer, admin: &signer, alice: &signer, bob: &signer) {
        setup(aptos_framework, admin, alice, bob);
        
        let alice_addr = signer::address_of(alice);
        let metadata = string::utf8(b"Invalid badge type");
        
        // Try to award an invalid badge type
        reputation::award_custom_badge(admin, alice_addr, 10, metadata); // 10 is not a valid badge type
    }

    #[test(aptos_framework = @std, admin = @tidmat, alice = @0x123, bob = @0x456)]
    fun test_automatic_badge_awarding(aptos_framework: &signer, admin: &signer, alice: &signer, bob: &signer) {
        setup(aptos_framework, admin, alice, bob);
        
        let alice_addr = signer::address_of(alice);
        
        // Create conditions for Novice Contributor badge (5 total contributions)
        // First, record 5 contributions
        let i = 0;
        while (i < 5) {
            reputation::record_contribution(alice_addr, false);
            i = i + 1;
        };
        
        // Check that Novice badge was awarded
        assert!(reputation::has_badge(alice_addr, reputation::get_badge_novice()), 0);
        
        // Create conditions for Quality Master badge (95+ quality score)
        reputation::update_reputation(admin, alice_addr, 0, 95);
        
        // Check that Quality Master badge was awarded
        assert!(reputation::has_badge(alice_addr, reputation::get_badge_quality()), 0);
        
        // Create conditions for Expert Contributor badge (1000+ reputation score)
        reputation::update_reputation(admin, alice_addr, 1000, 0);
        
        // Check that Expert badge was awarded
        assert!(reputation::has_badge(alice_addr, reputation::get_badge_expert()), 0);
    }
    
    #[test(aptos_framework = @std, admin = @tidmat, alice = @0x123, bob = @0x456)]
    fun test_consistent_contributor_badge(aptos_framework: &signer, admin: &signer, alice: &signer, bob: &signer) {
        setup(aptos_framework, admin, alice, bob);
        
        let alice_addr = signer::address_of(alice);
        
        // Record 10 contributions, 9 successful (90% success rate)
        let i = 0;
        while (i < 9) {
            reputation::record_contribution(alice_addr, true);
            i = i + 1;
        };

	let j = 0;
	while (j < 10) {
            reputation::record_contribution(alice_addr, false);
	    j = j + 1;
        };

        // Check that Consistent Contributor badge was awarded
        assert!(reputation::has_badge(alice_addr, reputation::get_badge_consistent()), 0);
    }
    
    #[test(aptos_framework = @std, admin = @tidmat, alice = @0x123, bob = @0x456)]
    fun test_experienced_contributor_badge(aptos_framework: &signer, admin: &signer, alice: &signer, bob: &signer) {
        setup(aptos_framework, admin, alice, bob);
        
        let alice_addr = signer::address_of(alice);
        
        // Record 20 successful contributions
        let i = 0;
        while (i < 20) {
            reputation::record_contribution(alice_addr, true);
            i = i + 1;
        };
        
        // Check that Experienced Contributor badge was awarded
        assert!(reputation::has_badge(alice_addr, reputation::get_badge_experienced()), 0);
    }

    #[test(aptos_framework = @std, admin = @tidmat, alice = @0x123, bob = @0x456, charlie = @0x789)]
    #[expected_failure(abort_code = reputation::EPROFILE_NOT_FOUND)]
    fun test_get_reputation_score_profile_not_found(aptos_framework: &signer, admin: &signer, alice: &signer, bob: &signer, charlie: &signer) {
        setup(aptos_framework, admin, alice, bob);
        
        // Charlie doesn't have a profile, should fail
        reputation::get_reputation_score(signer::address_of(charlie));
    }

    #[test(aptos_framework = @std, admin = @tidmat, alice = @0x123, bob = @0x456, charlie = @0x789)]
    fun test_has_badge_no_profile(aptos_framework: &signer, admin: &signer, alice: &signer, charlie: &signer) {
        reputation::init_module_for_test(aptos_framework, admin);
        
        // Charlie doesn't have a profile, has_badge should return false
        assert!(!reputation::has_badge(signer::address_of(charlie), reputation::get_badge_novice()), 0);
    }

    #[test(aptos_framework = @std, admin = @tidmat, alice = @0x123, bob = @0x456)]
    fun test_multiple_badges(aptos_framework: &signer, admin: &signer, alice: &signer, bob: &signer) {
        setup(aptos_framework, admin, alice, bob);
        
        let alice_addr = signer::address_of(alice);
        
        // Award multiple badges
        let metadata1 = string::utf8(b"Badge 1");
        let metadata2 = string::utf8(b"Badge 2");
        
        reputation::award_custom_badge(admin, alice_addr, reputation::get_badge_novice(), metadata1);
        reputation::award_custom_badge(admin, alice_addr, reputation::get_badge_quality(), metadata2);
        
        // Check that both badges exist
        assert!(reputation::has_badge(alice_addr, reputation::get_badge_novice()), 0);
        assert!(reputation::has_badge(alice_addr, reputation::get_badge_quality()), 0);
        
        // Check badge count
        let badges = reputation::get_all_badges(alice_addr);
        assert!(std::vector::length(&badges) == 2, 0);
    }
}
