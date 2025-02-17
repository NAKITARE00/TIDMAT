script {
    use std::signer;
    use std::vector;
    use tidmat::reputation;
    use tidmat::treasury;
    use tidmat::campaign;
    use tidmat::contribution;

    fun init_mod(admin: &signer) {
        contribution::init_contribution_module(admin);
        campaign::initialize_registry(admin);
        treasury::initialize_treasury(admin); // Call the new `initialize_treasury` function

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

        reputation::initialize_reputation_system(admin, min_scores, score_weights);
    }
}