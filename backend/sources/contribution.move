module tidmat::contribution {
    use std::signer;
    use std::vector;
    use std::error;
    use std::string::{Self, String};
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::timestamp;
    use aptos_framework::event;
    use aptos_framework::account;
    use tidmat::escrow;

    // Error codes
    const EINVALID_QUALITY_SCORE: u64 = 1;
    const ECONTRIBUTION_NOT_VERIFIED: u64 = 2;
    const ECONTRIBUTION_ALREADY_EXISTS: u64 = 3;
    const EUNAUTHORIZED_VERIFIER: u64 = 4;
    const EINVALID_PROOF: u64 = 5;

    struct VerificationProof has store, drop {
        contribution_id: u64,
        campaign_id: address,
        contributor: address,
        verifier: address,
        verification_method: String,
        authenticity_score: u8,
        proof_timestamp: u64,
        additional_metadata: vector<u8>,
    }

    struct VerificationEvent has drop, store {
        contribution_id: u64,
        campaign_id: address,
        verifier: address,
        authenticity_score: u8,
        timestamp: u64
    }

    struct Contribution has key, store {
        id: u64,
        campaign_id: address,
        contributor: address,
        data_hash: vector<u8>,
        quality_score: u8,
        is_verified: bool,
        submission_time: u64,
        verification_proof: VerificationProof,
        verifications: event::EventHandle<VerificationEvent>
    }

    struct ContributionTracker has key {
        total_contributions: u64,
        verified_contributions: u64,
        quality_threshold: u8,
    }

    public entry fun create_contribution_tracker(
        creator: &signer, 
        quality_threshold: u8
    ) {
        let creator_addr = signer::address_of(creator);
        assert!(quality_threshold >= 50 && quality_threshold <= 80, error::invalid_argument(EINVALID_QUALITY_SCORE));
        
        let tracker = ContributionTracker {
            total_contributions: 0,
            verified_contributions: 0,
            quality_threshold,
        };
        
        move_to(creator, tracker);
    }

    public entry fun submit_contribution<CoinType>(
        account: &signer,
        campaign_id: address,
        data_hash: vector<u8>
    ) acquires ContributionTracker {
        let contributor = signer::address_of(account);
        
        assert!(exists<ContributionTracker>(campaign_id), error::not_found(ECONTRIBUTION_NOT_VERIFIED));
        
        let tracker = borrow_global_mut<ContributionTracker>(campaign_id);
        tracker.total_contributions = tracker.total_contributions + 1;
        
        let empty_proof = VerificationProof {
            contribution_id: tracker.total_contributions,
            campaign_id,
            contributor,
            verifier: @0x0,
            verification_method: string::utf8(b"pending"),
            authenticity_score: 0,
            proof_timestamp: 0,
            additional_metadata: vector::empty()
        };

        let contribution = Contribution {
            id: tracker.total_contributions,
            campaign_id,
            contributor,
            data_hash,
            quality_score: 0,
            is_verified: false,
            submission_time: timestamp::now_seconds(),
            verification_proof: empty_proof,
            verifications: account::new_event_handle<VerificationEvent>(account)
        };
        
        move_to(account, contribution);
    }

    public entry fun create_verification_proof(
        verifier: &signer,
        contribution_id: u64,
        campaign_id: address,
        contributor: address,
        verification_method: vector<u8>,
        authenticity_score: u8,
        additional_metadata: vector<u8>
    ) acquires Contribution {
        assert!(authenticity_score <= 100, error::invalid_argument(EINVALID_PROOF));
        
        let contribution_ref = borrow_global_mut<Contribution>(contributor);
        assert!(contribution_ref.id == contribution_id, error::invalid_argument(EUNAUTHORIZED_VERIFIER));
        
        let verifier_addr = signer::address_of(verifier);
        let current_time = timestamp::now_seconds();

        let proof = VerificationProof {
            contribution_id,
            campaign_id,
            contributor,
            verifier: verifier_addr,
            verification_method: string::utf8(verification_method),
            authenticity_score,
            proof_timestamp: current_time,
            additional_metadata,
        };
        
        contribution_ref.verification_proof = proof;

        event::emit_event(&mut contribution_ref.verifications, VerificationEvent {
            contribution_id,
            campaign_id,
            verifier: verifier_addr,
            authenticity_score,
            timestamp: current_time
        });
    }

    public entry fun verify_contribution<CoinType>(
        verifier: &signer,
        campaign_id: address,
        contributor: address,
        quality_score: u8,
        reward_amount: u64
    ) acquires Contribution, ContributionTracker {
        assert!(quality_score <= 100, error::invalid_argument(EINVALID_QUALITY_SCORE));
        
        let contribution_ref = borrow_global_mut<Contribution>(contributor);
        let tracker = borrow_global_mut<ContributionTracker>(campaign_id);
        
        assert!(contribution_ref.campaign_id == campaign_id, error::invalid_argument(EUNAUTHORIZED_VERIFIER));
        
        contribution_ref.quality_score = quality_score;
        contribution_ref.is_verified = quality_score >= tracker.quality_threshold;
        
        if (contribution_ref.is_verified) {
            tracker.verified_contributions = tracker.verified_contributions + 1;
            escrow::release_funds<CoinType>(verifier, contributor);
        }
    }

    #[view]
    public fun get_contribution_details(contributor: address): (u64, address, vector<u8>, u8, bool) acquires Contribution {
        let contribution = borrow_global<Contribution>(contributor);
        (
            contribution.id,
            contribution.campaign_id,
            contribution.data_hash,
            contribution.quality_score,
            contribution.is_verified
        )
    }

    #[view]
    public fun get_verification_proof(contributor: address): (address, String, u8, u64) acquires Contribution {
        let contribution = borrow_global<Contribution>(contributor);
        let proof = &contribution.verification_proof;
        (
            proof.verifier,
            proof.verification_method,
            proof.authenticity_score,
            proof.proof_timestamp
        )
    }

    #[view]
    public fun get_contribution_tracker(campaign_id: address): (u64, u64, u8) acquires ContributionTracker {
        let tracker = borrow_global<ContributionTracker>(campaign_id);
        (
            tracker.total_contributions,
            tracker.verified_contributions,
            tracker.quality_threshold
        )
    }
}