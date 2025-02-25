#[test_only]
module tidmat::campaign_tests {
    use std::signer;
    use std::vector;
    use std::string;
    use std::option;
    use aptos_std::math64;
    use aptos_framework::timestamp;
    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_framework::object;
    use aptos_framework::primary_fungible_store;
    use tidmat::campaign;
    use tidmat::contribution;
    use tidmat::treasury;
    use tidmat::reputation;    
    use tidmat::stake;

    const REWARD_POOL: u64 = 1000;
    const MIN_CONTRIBUTIONS: u64 = 1;
    const MAX_CONTRIBUTIONS: u64 = 20;
    const QUALITY_THRESHOLD: u8 = 75;
    const SERVICE_FEE: u64 = 1;
    const CAMPAIGN_DURATION: u64 = 864000; // 24 hours

    fun setup_fa(aptos_framework: &signer, admin: &signer, creator: &signer, alice_contrib: &signer) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        timestamp::update_global_time_for_test_secs(1000);

	let owner_addr = signer::address_of(admin);
	let creator_amount = 20000;
	let alice_amount = 10000;

	let fa_obj_constructor_ref = &object::create_sticky_object(owner_addr);

	primary_fungible_store::create_primary_store_enabled_fungible_asset(
	    fa_obj_constructor_ref,
	    option::none(),
	    string::utf8(b"Test FA"),
	    string::utf8(b"TF"),
	    8,
	    string::utf8(b"url"),
	    string::utf8(b"url"),
	);

	primary_fungible_store::mint(
	    &fungible_asset::generate_mint_ref(fa_obj_constructor_ref),
	    signer::address_of(creator),
	    creator_amount
	);

	primary_fungible_store::mint(
	    &fungible_asset::generate_mint_ref(fa_obj_constructor_ref),
	    signer::address_of(alice_contrib),
	    alice_amount
	);

	treasury::init_module_for_test_with_fa(aptos_framework, admin, object::object_from_constructor_ref<Metadata>(fa_obj_constructor_ref));

 	contribution::init_module_for_test(aptos_framework, admin);
        campaign::init_module_for_test(aptos_framework, admin);
	stake::init_module_for_test_with_fa(aptos_framework, admin, object::object_from_constructor_ref<Metadata>(fa_obj_constructor_ref));
        reputation::init_module_for_test(aptos_framework, admin);
    }

    #[test(aptos_framework = @std, admin = @tidmat, creator = @0x123, alice_contrib = @0x456)]
    fun test_create_campaign_success(aptos_framework: &signer, admin: &signer, creator: &signer, alice_contrib: &signer) {
	setup_fa(aptos_framework, admin, creator, alice_contrib);

        let campaign_name = string::utf8(b"Test Campaign");
  	let sample_data = vector::empty<u8>();
	vector::append(&mut sample_data, b"sample_data");
	
	let data_type = vector::empty<u8>();
        vector::append(&mut data_type, b"text");

        campaign::create_campaign(
	    creator,
	    campaign_name, 
	    REWARD_POOL,
	    sample_data,
	    data_type,	
	    QUALITY_THRESHOLD,
	    timestamp::now_seconds() + CAMPAIGN_DURATION,
            MIN_CONTRIBUTIONS,
	    MAX_CONTRIBUTIONS,
	    SERVICE_FEE
        );

        let creator_addr = signer::address_of(creator);
        let (id, name, creator_from_campaign, reward_pool, _, _, quality_threshold, _, min_contribs, max_contribs, status) = campaign::get_campaign_details(creator_addr, 1);
	
        assert!(id == 1, 1);
        assert!(name == campaign_name, 2);
        assert!(creator_from_campaign == creator_addr, 3);
        assert!(reward_pool == REWARD_POOL, 4);
        assert!(quality_threshold == QUALITY_THRESHOLD, 5);
        assert!(min_contribs == MIN_CONTRIBUTIONS, 6);
        assert!(max_contribs == MAX_CONTRIBUTIONS, 7);
        assert!(status == campaign::get_status_active(), 8);
    }

    #[test(aptos_framework = @std, admin = @tidmat, creator = @0x123, alice_contrib = @0x456)]
    #[expected_failure(abort_code = campaign::EINVALID_CAMPAIGN_PARAMS)]
    fun test_create_campaign_invalid_quality_threshold(aptos_framework: &signer, admin: &signer, creator: &signer, alice_contrib: &signer) {
	setup_fa(aptos_framework, admin, creator, alice_contrib);

        let campaign_name = string::utf8(b"Test Campaign");
        let sample_data = vector::empty<u8>();
        let data_type = vector::empty<u8>();

        campaign::create_campaign(
            creator,
            campaign_name,
            REWARD_POOL,
            sample_data,
            data_type,
            90,
            timestamp::now_seconds() + CAMPAIGN_DURATION,
            MIN_CONTRIBUTIONS,
            MAX_CONTRIBUTIONS,
            SERVICE_FEE
        );
    }

    #[test(aptos_framework = @std, admin = @tidmat, creator = @0x123, alice_contrib = @0x456)]
    fun test_submit_and_verify_contribution(aptos_framework: &signer, admin: &signer, creator: &signer, alice_contrib: &signer) {
	setup_fa(aptos_framework, admin, creator, alice_contrib);
	
	let creator_addr = signer::address_of(creator);

        let campaign_name = string::utf8(b"Test Campaign");
        let sample_data = vector::empty<u8>();
        vector::append(&mut sample_data, b"sample_data");

        let data_type = vector::empty<u8>();
        vector::append(&mut data_type, b"text");

        campaign::create_campaign(
            creator,
            campaign_name,
            REWARD_POOL,
            sample_data,
            data_type,
            QUALITY_THRESHOLD,
            timestamp::now_seconds() + CAMPAIGN_DURATION,
            MIN_CONTRIBUTIONS,
            MAX_CONTRIBUTIONS,
            SERVICE_FEE
        );
	

	// Submit Contribution
	create_contribution(creator, alice_contrib, creator_addr, 1, 1);

	// Check Contribution Status
	let (contributions, verified_contributions) = contribution::get_contribution_tracker(1);
	let (_,_,_,status) = contribution::get_contributor_details(1);

	assert!(contributions == 1, 1);
	assert!(status == contribution::get_status_verified(), 2);
	assert!(vector::length(&verified_contributions) == 1, 3);
    }


    #[test(aptos_framework = @std, admin = @tidmat, creator = @0x123, alice_contrib = @0x456)]
    fun test_cancel_campaign(aptos_framework: &signer, admin: &signer, creator: &signer, alice_contrib: &signer) {
        setup_fa(aptos_framework, admin, creator, alice_contrib);
	
        let campaign_name = string::utf8(b"Test Campaign");
        let sample_data = vector::empty<u8>();
        vector::append(&mut sample_data, b"sample_data");

        let data_type = vector::empty<u8>();
        vector::append(&mut data_type, b"text");

        campaign::create_campaign(
            creator,
            campaign_name,
            REWARD_POOL,
            sample_data,
            data_type,
            QUALITY_THRESHOLD,
            timestamp::now_seconds() + CAMPAIGN_DURATION,
            MIN_CONTRIBUTIONS,
            MAX_CONTRIBUTIONS,
            SERVICE_FEE
        );

	// Cancel Campaign
	campaign::cancel_campaign(creator, 1);

	// Verify Campaign Status
	let creator_addr = signer::address_of(creator);
	let status = campaign::get_campaign_status(creator_addr, 1);

	assert!(status == campaign::get_status_cancelled(), 1);
    }


    #[test(aptos_framework = @std, admin = @tidmat, creator = @0x123, alice_contrib = @0x456)]
    fun test_finalize_campaign(aptos_framework: &signer, admin: &signer, creator: &signer, alice_contrib: &signer) {
        setup_fa(aptos_framework, admin, creator, alice_contrib);

        let campaign_name = string::utf8(b"Test Campaign");
        let sample_data = vector::empty<u8>();
        vector::append(&mut sample_data, b"sample_data");

        let data_type = vector::empty<u8>();
        vector::append(&mut data_type, b"text");

        campaign::create_campaign(
            creator,
            campaign_name,
            REWARD_POOL,
            sample_data,
            data_type,
            QUALITY_THRESHOLD,
            timestamp::now_seconds() + CAMPAIGN_DURATION,
            MIN_CONTRIBUTIONS,
            MAX_CONTRIBUTIONS,
            SERVICE_FEE
        );

        // Create one contribution as its equal to the min_contrib for this campaign
        create_contribution(creator, alice_contrib, signer::address_of(creator), 1, 1);

	// Accept all Campaign Contributions
	campaign::accept_verified_contributions(creator, 1);

        // Finalize Campaign
        campaign::finalize_campaign(creator, 1);

        // Verify Campaign Status
        let creator_addr = signer::address_of(creator);
        let status = campaign::get_campaign_status(creator_addr, 1);

        assert!(status == campaign::get_status_completed(), 1);
    }

    #[test(aptos_framework = @std, admin = @tidmat, creator = @0x123, alice_contrib = @0x456)]
    fun test_get_campaign_ids(aptos_framework: &signer, admin: &signer, creator: &signer, alice_contrib: &signer) {
        setup_fa(aptos_framework, admin, creator, alice_contrib);
	
	let campaign_ids = campaign::get_campaign_ids();
	assert!(vector::length(&campaign_ids) == 0, 1);
    }

    #[test(aptos_framework = @std, admin = @tidmat, creator = @0x123, alice_contrib = @0x456)]
    fun test_get_creator_campaign_ids(aptos_framework: &signer, admin: &signer, creator: &signer, alice_contrib: &signer) {
        setup_fa(aptos_framework, admin, creator, alice_contrib);
	
	let campaign_name = string::utf8(b"Test Campaign");
        let sample_data = vector::empty<u8>();
        vector::append(&mut sample_data, b"sample_data");

        let data_type = vector::empty<u8>();
        vector::append(&mut data_type, b"text");

        campaign::create_campaign(
            creator,
            campaign_name,
            REWARD_POOL,
            sample_data,
            data_type,
            QUALITY_THRESHOLD,
            timestamp::now_seconds() + CAMPAIGN_DURATION,
            MIN_CONTRIBUTIONS,
            MAX_CONTRIBUTIONS,
            SERVICE_FEE
        );

	let creator_addr = signer::address_of(creator);
	let campaign_ids = campaign::get_creator_campaign_ids(creator_addr);

	assert!(vector::length(&campaign_ids) == 1, 1);
	assert!(*vector::borrow(&campaign_ids, 0) == 1, 2);
    }

    #[test(aptos_framework = @std, admin = @tidmat, creator = @0x123, alice_contrib = @0x456)]
    fun test_create_campaign_service_fee_debited(aptos_framework: &signer, admin: &signer, creator: &signer, alice_contrib: &signer) {
        setup_fa(aptos_framework, admin, creator, alice_contrib);

        let campaign_name = string::utf8(b"Test Campaign");
        let sample_data = vector::empty<u8>();
        vector::append(&mut sample_data, b"sample_data");

        let data_type = vector::empty<u8>();
        vector::append(&mut data_type, b"text");

        campaign::create_campaign(
            creator,
            campaign_name,
            REWARD_POOL,
            sample_data,
            data_type,
            QUALITY_THRESHOLD,
            timestamp::now_seconds() + CAMPAIGN_DURATION,
            MIN_CONTRIBUTIONS,
            MAX_CONTRIBUTIONS,
            SERVICE_FEE
        );

	let bal = treasury::get_treasury_bal();
	let percentage_cut = math64::mul_div(REWARD_POOL, SERVICE_FEE, 100);
	
	assert!(bal == percentage_cut, 1);
    }

    fun create_contribution(creator: &signer, contributor: &signer, creator_addr: address, campaign_id: u64, contributor_id: u64) {
 	let contribution_data = vector::empty<u8>();
        vector::append(&mut contribution_data, b"test_data");

        campaign::submit_contribution(contributor, creator_addr, campaign_id, contribution_data);

        // Verify Contribution
        campaign::update_contribution_status(creator, creator_addr, campaign_id, contributor_id, contribution::get_status_verified());
    }

}
