module backend::ContributionEscrow {
    use std::signer;
    use std::vector;
    use 0x1::coin;  
    
    // Assuming you have a custom coin type called MyCoin
    struct MyCoin has store {}

    struct Contribution has key, store {
        id: u64,
        contributor: address,
        data_hash: vector<u8>,
        quality_score: u8,
        is_verified: bool,
    }

    struct Escrow has key, store {
        campaign_id: address,
        total_locked: u64,
        contributions: vector<Contribution>,
    }

    public entry fun submit_contribution(
        account: &signer,
        campaign_id: address,
        data_hash: vector<u8>
    ) {
        let contributor = signer::address_of(account);
        let contribution = Contribution {
            id: 0,
            contributor,
            data_hash,
            quality_score: 0,
            is_verified: false,
        };

        move_to(account, contribution);
    }

    public entry fun verify_contribution(
        account: &signer,
        contributor: address,
        quality_score: u8
    ) acquires Contribution {
        assert!(quality_score <= 100, 100);

        let contribution_ref = borrow_global_mut<Contribution>(contributor);
        contribution_ref.quality_score = quality_score;
        contribution_ref.is_verified = quality_score >= 50;
    }

    public entry fun release_rewards(
        account: &signer,
        campaign_id: address,
        contributor: address,
        reward_amount: u64
    ) acquires Escrow, Contribution {
        let escrow_ref = borrow_global_mut<Escrow>(campaign_id);
        let contribution_ref = borrow_global<Contribution>(contributor);

        assert!(contribution_ref.is_verified, 101);
        assert!(escrow_ref.total_locked >= reward_amount, 102);

        escrow_ref.total_locked -= reward_amount;
        // Specify the type of coin being transferred
        coin::transfer<MyCoin>(account, contributor, reward_amount);  // Correct transfer statement
    }
} 
