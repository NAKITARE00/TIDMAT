# Escrow Module Documentation

## Overview
The `escrow.move` module handles the locking, refunding, and distribution of funds for campaigns. It is primarily used within the `campaign` contract and does not contain entry functions for direct interaction from the frontend.

## Key Features
- **Escrow Creation:** Locks the campaign's reward pool in a staking pool.
- **Fund Release:** Distributes rewards among verified contributors.
- **Refund Mechanism:** Allows campaign creators to reclaim funds if the campaign is canceled.
- **Treasury Cut:** Deducts a marketplace fee when funds are released.

## Important Notes
- This module is not directly accessible from the frontend.
- It is designed to be used internally by the `campaign` contract.
- `stake.move` is used for staking and fund transfers.
- `contribution.move` is used for handling campaign contributions.
- `treasury.move` processes marketplace fees.

## Structs
### `Escrow`
Represents the escrow contract for a campaign.
```move
struct Escrow has key, store, drop, copy {
    campaign_id: u64,        // ID of the campaign
    creator: address,        // Address of the campaign creator
    total_locked: u64,       // Total locked funds
    pool_bal: u64,           // Available balance in the escrow
    locked_funds: Object<stake::StakePool>  // Staked funds
}
```

## Functions
### `create_escrow(creator: &signer, campaign_id: u64, total_reward_pool: u64) -> Escrow`
Creates a new escrow instance and locks the funds in a stake pool.
- **Parameters:**
  - `creator`: Signer of the campaign creator.
  - `campaign_id`: Unique ID of the campaign.
  - `total_reward_pool`: The total amount of tokens to be locked in escrow.
- **Returns:**
  - A new `Escrow` instance.

### `refund(creator: &signer, escrow: Escrow, apply_fee: bool)`
Refunds the locked funds to the campaign creator. If `apply_fee` is `true`, a 10% fee is deducted.
- **Parameters:**
  - `creator`: Signer of the campaign creator.
  - `escrow`: The escrow object to refund from.
  - `apply_fee`: Boolean flag to determine if a fee should be applied.
- **Effects:**
  - Refunds the remaining balance from `locked_funds` to the creator.
  - Updates the escrow balance.

### `release_funds(creator: &signer, escrow: Escrow, contributions: vector<contribution::Contribution>, verified_contributions: u64)`
Distributes the escrowed funds among verified contributors.
- **Parameters:**
  - `creator`: Signer of the campaign creator.
  - `escrow`: The escrow object holding the locked funds.
  - `contributions`: A vector of verified contributions.
  - `verified_contributions`: The number of verified contributions.
- **Effects:**
  - Transfers 1% of the total balance to the marketplace treasury.
  - Distributes the remaining balance equally among verified contributors.

### `get_escrow_pool_bal(escrow: Escrow) -> u64`
Retrieves the available balance of the escrow.
- **Parameters:**
  - `escrow`: The escrow object.
- **Returns:**
  - The available balance in the escrow.

## TODOs & Placeholders
- **TODO:** Update the stake pool address in `stake.move` to reference the correct token metadata.

## Conclusion
The `escrow.move` module is essential for managing funds within campaigns but is not meant to be accessed directly by the frontend. Instead, interactions should be done through the `campaign` contract, which will provide the necessary entry functions.

