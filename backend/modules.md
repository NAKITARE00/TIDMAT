# TIDMAT Move Modules

This documentation outlines the APIs available in the Campaign, Escrow, and Contribution modules of TIDMAT.

## 1. Campaign Module (`tidmat::campaign`)

The Campaign module manages data collection campaigns with configurable parameters and reward distribution.

### Functions

#### `create_campaign<CoinType>`
Creates a new data collection campaign.

**Signature:**
```move
public entry fun create_campaign<CoinType>(
    creator: &signer,
    total_reward_pool: u64,
    data_type: vector<u8>,
    quality_threshold: u8,
    deadline: u64,
    min_contributions: u64,
    max_contributions: u64,
    service_fee_percentage: u8
)
```

**Parameters:**
- `creator`: Campaign creator's signer
- `total_reward_pool`: Total amount of rewards for contributors
- `data_type`: Type of data being collected
- `quality_threshold`: Minimum quality score required (50-80)
- `deadline`: Campaign end timestamp
- `min_contributions`: Minimum required contributions
- `max_contributions`: Maximum allowed contributions
- `service_fee_percentage`: Platform fee percentage (max 20%)

**Usage Example:**
```move
campaign::create_campaign<AptosCoin>(
    &signer,
    1000000,  // 1M tokens
    b"image_data",
    70,  // 70% quality threshold
    1708041600,  // deadline timestamp
    100,  // min contributions
    1000,  // max contributions
    5  // 5% service fee
);
```

#### `cancel_campaign<CoinType>`
Cancels an active campaign and processes refunds.

**Signature:**
```move
public entry fun cancel_campaign<CoinType>(
    creator: &signer,
    campaign_id: u64
)
```

#### `finalize_campaign<CoinType>`
Finalizes a campaign after its deadline.

**Signature:**
```move
public entry fun finalize_campaign<CoinType>(
    creator: &signer,
    campaign_id: u64
)
```

#### View Functions

##### `get_campaign_details`
Returns campaign details.

**Signature:**
```move
#[view]
public fun get_campaign_details(creator_addr: address): (u64, address, u64, u64, u8, u64, u8)
```

**Returns:**
- Campaign ID
- Creator address
- Total reward pool
- Remaining rewards
- Quality threshold
- Deadline
- Status

##### `get_campaign_status`
Returns campaign status.

**Signature:**
```move
#[view]
public fun get_campaign_status(creator_addr: address): u8
```

## 2. Escrow Module (`tidmat::escrow`)

The Escrow module handles secure fund management between campaign creators and contributors.

### Functions

#### `create_escrow<CoinType>`
Creates a new escrow agreement.

**Signature:**
```move
public entry fun create_escrow<CoinType>(
    creator: &signer,
    contributor_address: address,
    amount: u64
)
```

#### `fund_escrow<CoinType>`
Funds an existing escrow agreement.

**Signature:**
```move
public entry fun fund_escrow<CoinType>(
    contributor: &signer,
    creator_address: address
)
```

#### `release_funds<CoinType>`
Releases funds to the contributor.

**Signature:**
```move
public entry fun release_funds<CoinType>(
    creator: &signer,
    contributor_address: address
)
```

#### `refund<CoinType>`
Processes a refund to the contributor.

**Signature:**
```move
public entry fun refund<CoinType>(
    creator: &signer,
    contributor_address: address
)
```

#### View Functions

##### `get_escrow_state`
Returns the current state of an escrow.

**Signature:**
```move
#[view]
public fun get_escrow_state<CoinType>(creator_address: address): EscrowState
```

##### `get_escrow_amount`
Returns the escrow amount.

**Signature:**
```move
#[view]
public fun get_escrow_amount<CoinType>(creator_address: address): u64
```

## 3. Contribution Module (`tidmat::contribution`)

The Contribution module manages data submissions and verification processes.

### Functions

#### `create_contribution_tracker`
Creates a tracker for campaign contributions.

**Signature:**
```move
public entry fun create_contribution_tracker(
    creator: &signer,
    quality_threshold: u8
)
```

#### `submit_contribution<CoinType>`
Submits a new contribution to a campaign.

**Signature:**
```move
public entry fun submit_contribution<CoinType>(
    account: &signer,
    campaign_id: address,
    data_hash: vector<u8>
)
```

#### `create_verification_proof`
Creates a verification proof for a contribution.

**Signature:**
```move
public entry fun create_verification_proof(
    verifier: &signer,
    contribution_id: u64,
    campaign_id: address,
    contributor: address,
    verification_method: vector<u8>,
    authenticity_score: u8,
    additional_metadata: vector<u8>
)
```

#### `verify_contribution<CoinType>`
Verifies a contribution and processes rewards if quality threshold is met.

**Signature:**
```move
public entry fun verify_contribution<CoinType>(
    verifier: &signer,
    campaign_id: address,
    contributor: address,
    quality_score: u8,
    reward_amount: u64
)
```

#### View Functions

##### `get_contribution_details`
Returns contribution details.

**Signature:**
```move
#[view]
public fun get_contribution_details(contributor: address): (u64, address, vector<u8>, u8, bool)
```

**Returns:**
- Contribution ID
- Campaign ID
- Data hash
- Quality score
- Verification status

##### `get_verification_proof`
Returns verification proof details.

**Signature:**
```move
#[view]
public fun get_verification_proof(contributor: address): (address, String, u8, u64)
```

**Returns:**
- Verifier address
- Verification method
- Authenticity score
- Proof timestamp

##### `get_contribution_tracker`
Returns contribution tracking information.

**Signature:**
```move
#[view]
public fun get_contribution_tracker(campaign_id: address): (u64, u64, u8)
```

**Returns:**
- Total contributions
- Verified contributions
- Quality threshold

## Error Handling

Each module includes specific error codes for various failure scenarios. Common error cases include:
- Invalid parameters
- Unauthorized actions
- Invalid state transitions
- Resource not found
- Already existing resources

## Events

Each module emits events for important state changes:
- Campaign: Creation, activation, completion, cancellation
- Escrow: Creation, funding, release, refund
- Contribution: Submission, verification

## Usage Flow

1. Create a campaign using `create_campaign`
2. Contributors submit data using `submit_contribution`
3. Verifiers create proofs using `create_verification_proof`
4. Verify contributions using `verify_contribution`
5. Finalize campaign using `finalize_campaign`

## Notes

- All monetary values are in base units (no decimals)
- Timestamps are in Unix seconds
- Quality thresholds are percentages (0-100)
- Service fees are percentages (0-20)