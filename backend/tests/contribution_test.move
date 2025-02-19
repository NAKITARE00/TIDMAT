script {
    use std::signer;
    use std::vector;
    use std::debug;
    use tidmat::contribution;

    fun main(admin: &signer, contributor: &signer) {
        // Initialize the module
        contribution::init_contribution_module(admin);
        debug::print(&b"Contribution module initialized successfully.");

        // Ensure the contribution tracker exists
        assert!(contribution::contribution_tracker_exists(signer::address_of(admin)), 1);
        debug::print(&b"Contribution tracker exists.");

        // Define a campaign ID
        let campaign_id = 1001;
        let test_data = b"Sample Contribution Data";

        // Submit a contribution
        contribution::submit_a_contribution(contributor, campaign_id, test_data);
        debug::print(&b"Contribution submitted successfully.");

        // Retrieve contributions for the campaign
        let contributions = contribution::get_campaign_contributions(campaign_id);
        assert!(vector::length(&contributions) == 1, 2);
        debug::print(&b"Campaign contributions retrieved successfully.");

        // Fetch contributor details
        let contrib_id = vector::borrow(&contributions, 0);
        let (retrieved_campaign, contributor_addr, retrieved_data, status) = 
            contribution::get_contributor_details(*contrib_id);
        
        assert!(retrieved_campaign == campaign_id, 3);
        assert!(contributor_addr == signer::address_of(contributor), 4);
        assert!(retrieved_data == test_data, 5);
        assert!(status == contribution::get_status_submitted(), 6);
        debug::print(&b"Contributor details verified successfully.");

        // Update contribution status to verified
        contribution::update_contrib_status(contribution::get_status_verified(), *contrib_id, campaign_id);
        debug::print(&b"Contribution status updated to VERIFIED.");

        // Accept verified contributions
        contribution::accept_campaign_contributions(campaign_id);
        debug::print(&b"All verified contributions accepted successfully.");

        // Check if the contribution status is now ACCEPTED
        let (_, _, _, final_status) = contribution::get_contributor_details(*contrib_id);
        assert!(final_status == contribution::get_status_accepted(), 7);
        debug::print(&b"Final contribution status verified as ACCEPTED.");
    }
}