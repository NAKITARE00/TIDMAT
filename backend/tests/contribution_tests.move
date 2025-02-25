#[test_only]
module tidmat::contribution_tests {
    use std::signer;
    use std::vector;
    use std::string;
    use aptos_framework::timestamp;
    use tidmat::contribution;

    // Helper function to setup the test environment
    fun setup(aptos_framework: &signer, admin: &signer) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        timestamp::update_global_time_for_test_secs(1000);
        
        contribution::init_module_for_test(aptos_framework, admin);
    }

    // Helper function to create test data
    fun create_test_data(): vector<u8> {
        let data = vector::empty<u8>();
        vector::append(&mut data, b"test_contribution_data");
        data
    }
    
    #[test(aptos_framework = @std, admin = @tidmat, contributor_1 = @0x456)]
    fun test_submit_contribution_success(aptos_framework: &signer, admin: &signer, contributor_1: &signer) {
        setup(aptos_framework, admin);
        
        let campaign_id = 1;
        let test_data = create_test_data();
        
        // Submit contribution
        contribution::submit_a_contribution(contributor_1, campaign_id, test_data);
        
        // Verify the contribution was added correctly
        let contributions = contribution::get_campaign_contributions(campaign_id);
        assert!(vector::length(&contributions) == 1, 0);
        assert!(*vector::borrow(&contributions, 0) == 1, 0); // First contribution ID should be 1
        
        // Verify contribution details
        let (c_campaign_id, contributor, data, status) = contribution::get_contributor_details(1);
        assert!(c_campaign_id == campaign_id, 0);
        assert!(contributor == signer::address_of(contributor_1), 0);
        assert!(data == test_data, 0);
        assert!(status == contribution::get_status_submitted(), 0);
    }
    
    #[test(aptos_framework = @std, admin = @tidmat, contributor_1 = @0x456)]
    #[expected_failure(abort_code = contribution::EINVALID_CONTRIBUTION_PARAMS)]
    fun test_submit_contribution_empty_data(aptos_framework: &signer, admin: &signer, contributor_1: &signer) {
        setup(aptos_framework, admin);
        
        let campaign_id = 1;
        let empty_data = vector::empty<u8>();
        
        // Should fail with empty data
        contribution::submit_a_contribution(contributor_1, campaign_id, empty_data);
    }
    
    #[test(aptos_framework = @std, admin = @tidmat, contributor_1 = @0x456)]
    #[expected_failure(abort_code = contribution::ECONTRIBUTION_ALREADY_EXISTS)]
    fun test_submit_contribution_duplicate(aptos_framework: &signer, admin: &signer, contributor_1: &signer) {
        setup(aptos_framework, admin);
        
        let campaign_id = 1;
        let test_data = create_test_data();
        
        // Submit contribution first time
        contribution::submit_a_contribution(contributor_1, campaign_id, test_data);
        
        // Submit again with same campaign_id and contributor - should fail
        contribution::submit_a_contribution(contributor_1, campaign_id, test_data);
    }

    #[test(aptos_framework = @std, admin = @tidmat, contributor_1 = @0x456)]
    fun test_update_contribution_status(aptos_framework: &signer, admin: &signer, contributor_1: &signer) {
        setup(aptos_framework, admin);
        
        let campaign_id = 1;
        let test_data = create_test_data();
        
        // Submit contribution
        contribution::submit_a_contribution(contributor_1, campaign_id, test_data);
        
        // Update status to verified
        contribution::update_contrib_status(contribution::get_status_verified(), 1, campaign_id);
        
        // Check updated status
        let (_, _, _, status) = contribution::get_contributor_details(1);
        assert!(status == contribution::get_status_verified(), 0);
        
        // Update status to rejected
        contribution::update_contrib_status(contribution::get_status_rejected(), 1, campaign_id);
        
        // Check updated status
        let (_, _, _, status) = contribution::get_contributor_details(1);
        assert!(status == contribution::get_status_rejected(), 0);
    }
    
    #[test(aptos_framework = @std, admin = @tidmat, contributor_1 = @0x456)]
    #[expected_failure(abort_code = contribution::EINVALID_CONTRIBUTION_PARAMS)]
    fun test_update_contribution_invalid_status(aptos_framework: &signer, admin: &signer, contributor_1: &signer) {
        setup(aptos_framework, admin);
        
        let campaign_id = 1;
        let test_data = create_test_data();
        
        // Submit contribution
        contribution::submit_a_contribution(contributor_1, campaign_id, test_data);
        
        // Try to update with invalid status (using submitted status which is not allowed in update)
        contribution::update_contrib_status(contribution::get_status_submitted(), 1, campaign_id);
    }
    
    #[test(aptos_framework = @std, admin = @tidmat, contributor_1 = @0x456)]
    #[expected_failure(abort_code = contribution::ECONTRIBUTION_NOT_FOUND)]
    fun test_update_contribution_not_found(aptos_framework: &signer, admin: &signer, contributor_1: &signer) {
        setup(aptos_framework, admin);
        
        let campaign_id = 1;
        
        // Try to update non-existent contribution
        contribution::update_contrib_status(contribution::get_status_verified(), 999, campaign_id);
    }
    
    #[test(aptos_framework = @std, admin = @tidmat, contributor_1 = @0x456)]
    fun test_accept_contribution(aptos_framework: &signer, admin: &signer, contributor_1: &signer) {
        setup(aptos_framework, admin);
        
        let campaign_id = 1;
        let test_data = create_test_data();
        
        // Submit contribution
        contribution::submit_a_contribution(contributor_1, campaign_id, test_data);
        
        // First verify the contribution
        contribution::update_contrib_status(contribution::get_status_verified(), 1, campaign_id);
        
        // Accept the contribution
        contribution::accept_a_contribution(1);
        
        // Check the status is now accepted
        let (_, _, _, status) = contribution::get_contributor_details(1);
        assert!(status == contribution::get_status_accepted(), 0);
    }
    
    #[test(aptos_framework = @std, admin = @tidmat, contributor_1 = @0x456)]
    fun test_reject_contribution(aptos_framework: &signer, admin: &signer, contributor_1: &signer) {
        setup(aptos_framework, admin);
        
        let campaign_id = 1;
        let test_data = create_test_data();
        
        // Submit contribution
        contribution::submit_a_contribution(contributor_1, campaign_id, test_data);
        
        // Reject the contribution
        contribution::reject_a_contribution(1);
        
        // Check the status is now rejected
        let (_, _, _, status) = contribution::get_contributor_details(1);
        assert!(status == contribution::get_status_rejected(), 0);
    }
    
    #[test(aptos_framework = @std, admin = @tidmat, contributor_1 = @0x456, contributor_2 = @0x789)]
    fun test_accept_campaign_contributions(aptos_framework: &signer, admin: &signer, contributor_1: &signer, contributor_2: &signer) {
        setup(aptos_framework, admin);
        
        let campaign_id = 1;
        let test_data_1 = create_test_data();
        let test_data_2 = create_test_data();
        
        // Submit two contributions
        contribution::submit_a_contribution(contributor_1, campaign_id, test_data_1);
        contribution::submit_a_contribution(contributor_2, campaign_id, test_data_2);
        
        // Verify both contributions
        contribution::update_contrib_status(contribution::get_status_verified(), 1, campaign_id);
        contribution::update_contrib_status(contribution::get_status_verified(), 2, campaign_id);
        
        // Accept all verified contributions for the campaign
        contribution::accept_campaign_contributions(campaign_id);
        
        // Check both contributions are now accepted
        let (_, _, _, status1) = contribution::get_contributor_details(1);
        let (_, _, _, status2) = contribution::get_contributor_details(2);
        assert!(status1 == contribution::get_status_accepted(), 0);
        assert!(status2 == contribution::get_status_accepted(), 0);
        
        // Check accepted contributions list
        let accepted = contribution::get_accepted_contributions(campaign_id);
        assert!(vector::length(&accepted) == 2, 0);
    }
    
    #[test(aptos_framework = @std, admin = @tidmat, contributor_1 = @0x456, contributor_2 = @0x789)]
    #[expected_failure(abort_code = contribution::EINVALID_CONTRIBUTION_PARAMS)]
    fun test_accept_campaign_no_verified(aptos_framework: &signer, admin: &signer, contributor_1: &signer, contributor_2: &signer) {
        setup(aptos_framework, admin);
        
        let campaign_id = 1;
        let test_data = create_test_data();
        
        // Submit contribution but don't verify it
        contribution::submit_a_contribution(contributor_1, campaign_id, test_data);
        
        // Try to accept all verified contributions - should fail as none are verified
        contribution::accept_campaign_contributions(campaign_id);
    }
    
    #[test(aptos_framework = @std, admin = @tidmat, contributor_1 = @0x456, contributor_2 = @0x789)]
    fun test_get_contribution_tracker(aptos_framework: &signer, admin: &signer, contributor_1: &signer, contributor_2: &signer) {
        setup(aptos_framework, admin);
        
        let campaign_id = 1;
        let test_data_1 = create_test_data();
        let test_data_2 = create_test_data();
        
        // Submit two contributions
        contribution::submit_a_contribution(contributor_1, campaign_id, test_data_1);
        contribution::submit_a_contribution(contributor_2, campaign_id, test_data_2);
        
        // Verify only the first contribution
        contribution::update_contrib_status(contribution::get_status_verified(), 1, campaign_id);
        
        // Check contribution tracker
        let (total_contributions, verified_contributions) = contribution::get_contribution_tracker(campaign_id);
        assert!(total_contributions == 2, 0);
        assert!(vector::length(&verified_contributions) == 1, 0);
        
        // Verify the second contribution
        contribution::update_contrib_status(contribution::get_status_verified(), 2, campaign_id);
        
        // Check contribution tracker again
        let (total_contributions, verified_contributions) = contribution::get_contribution_tracker(campaign_id);
        assert!(total_contributions == 2, 0);
        assert!(vector::length(&verified_contributions) == 2, 0);
    }
    
    #[test(aptos_framework = @std, admin = @tidmat, contributor_1 = @0x456, contributor_2 = @0x789)]
    fun test_multiple_campaigns(aptos_framework: &signer, admin: &signer, contributor_1: &signer, contributor_2: &signer) {
        setup(aptos_framework, admin);
        
        let campaign_id_1 = 1;
        let campaign_id_2 = 2;
        let test_data = create_test_data();
        
        // Submit contribution to first campaign
        contribution::submit_a_contribution(contributor_1, campaign_id_1, test_data);
        
        // Submit contribution to second campaign
        contribution::submit_a_contribution(contributor_1, campaign_id_2, test_data);
        
        // Submit another contribution to first campaign
        contribution::submit_a_contribution(contributor_2, campaign_id_1, test_data);
        
        // Check campaign 1 contributions
        let contributions_1 = contribution::get_campaign_contributions(campaign_id_1);
        assert!(vector::length(&contributions_1) == 2, 0);
        
        // Check campaign 2 contributions
        let contributions_2 = contribution::get_campaign_contributions(campaign_id_2);
        assert!(vector::length(&contributions_2) == 1, 0);
    }
    
    #[test(aptos_framework = @std, admin = @tidmat)]
    fun test_contribution_exists_check(aptos_framework: &signer, admin: &signer) {
        setup(aptos_framework, admin);
        
        assert!(contribution::contribution_tracker_exists(@tidmat), 0);
        assert!(!contribution::contribution_tracker_exists(@0x123), 0);
    }
    
    #[test(aptos_framework = @std, admin = @tidmat)]
    fun test_get_contributor_addr(aptos_framework: &signer, admin: &signer) {
        setup(aptos_framework, admin);
        
        let contributor_addr = @0x456;
        let contrib = contribution::create_contrib_for_test(
            1, // contrib_id
            1, // campaign_id
            contributor_addr,
            create_test_data(),
            contribution::get_status_submitted()
        );
        
        assert!(contribution::get_contributor_addr(&contrib) == contributor_addr, 0);
    }
}
