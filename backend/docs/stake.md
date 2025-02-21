# Stake Module Documentation

## Overview
The `stake.move` module implements a staking pool system that allows funds to be locked and managed within a contract. This module is **not** designed for direct frontend interaction as it does not expose any `entry` functions. Instead, it is intended to be called within the Escrow contract, which manages staking operations.

## Key Components
### 1. `StakePool`
A struct that represents the staking pool with the following properties:
- `fa_metadata_object`: The fungible asset metadata.
- `stake_store`: The storage for staking rewards.
- `total_staked`: Total amount staked.
- `available_bal`: Available balance for withdrawals.
- `owner`: The owner of the pool.
- `controller`: A `StoreController` that acts on behalf of the owner.

### 2. `StoreController`
A struct that helps manage the staking pool, providing an `ExtendRef` to authorize store interactions.

## Functions 

### 1. `create_creator_store_ctlr(owner: &signer) -> StoreController`
Creates a `StoreController` for managing the staking pool.

### 2. `create_stake_pool(owner: &signer, initial_stake: u64) -> Object<StakePool>`
- Initializes a staking pool with an `initial_stake`.
- Requires the owner to have enough balance.
- Moves the initial stake from the owner to the staking pool.

### 3. `transfer_from_pool(pool_obj: Object<StakePool>, recipient: address, amount: u64)`
- Transfers an amount from the pool to the recipient.
- Ensures there are enough funds available.

### 4. `get_pool_bal(pool: Object<StakePool>) -> u64`
- Returns the available balance of a staking pool.

## Internal Helper Functions
These are used internally and should not be called directly from the Escrow contract or frontend:
- `generate_store_signer(extend_ref: &ExtendRef) -> signer`
- `get_token_metadata() -> Object<Metadata>` (Needs a valid token address, **TODO**)

## Integration with Escrow Contract
- The Escrow contract will interact with `stake.move` to create pools, manage deposits, and handle stake-related operations.

## TODOs
- **Update `get_token_metadata()`**: Replace `@fa_metadata_addr` with the actual fungible asset metadata address.

## Error Codes
- `EINSUFFICIENT_FUNDS (1)`: Not enough balance.
- `EUNAUTHORIZED (2)`: Unauthorized access.
- `ESTAKE_NOT_FOUND (3)`: Stake pool does not exist.
- `EINVALID_AMOUNT (4)`: Invalid staking amount.
- `EAMOUNT_ZERO (5)`: Staking amount is zero.
- `ENOT_ENOUGH_BAL (6)`: Not enough balance in the staking pool.

## Conclusion
This module is **not** directly callable from the frontend but serves as a staking backend for the Escrow contract.
