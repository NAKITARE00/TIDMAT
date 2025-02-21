# Campaign Module Documentation

## Overview
The `campaign` module in Move is responsible for managing data contribution campaigns. It allows users (creators) to create campaigns, track contributions, manage escrowed reward pools, and distribute funds based on verified contributions.

This document provides a detailed guide to help frontend and backend developers understand how to interact with the module.

## Features
- Campaign creation and management
- Contribution tracking and verification
- Reward pool escrow and fund distribution
- Campaign cancellation and refunds
- Querying campaigns and their statuses

## Key Constants
| Constant | Description |
|----------|-------------|
| `EINVALID_CAMPAIGN_PARAMS` | Error code for invalid campaign parameters |
| `ECAMPAIGN_NOT_FOUND` | Error code when a campaign is not found |
| `EUNAUTHORIZED_ACTION` | Error code for unauthorized actions |
| `ECAMPAIGN_EXPIRED` | Error code when the campaign has expired |
| `ECAMPAIGN_ALREADY_EXISTS` | Error code when a campaign with the same ID already exists |
| `EREGISTRY_NOT_FOUND` | Error code when the campaign registry is not found |
| `ESTORE_NOT_FOUND` | Error code when the creator campaign store is not found |
| `EINVALID_CONTRIBUTION_PARAMS` | Error code for invalid contribution parameters |
| `ECONTRIBUTION_NOT_FOUND` | Error code when a contribution is not found |

## Campaign Status Codes
| Status Code | Description |
|-------------|-------------|
| `CAMPAIGN_STATUS_DRAFT (1)` | Campaign is in draft mode |
| `CAMPAIGN_STATUS_ACTIVE (2)` | Campaign is active and accepting contributions |
| `CAMPAIGN_STATUS_COMPLETED (3)` | Campaign has been successfully completed |
| `CAMPAIGN_STATUS_CANCELLED (4)` | Campaign has been canceled |

## Data Structures
### `Campaign`
A campaign object contains:
- `id`: Unique campaign ID
- `name`: Campaign name
- `creator`: Address of the creator
- `reward_pool`: Total reward pool
- `escrow_c`: Escrow contract for funds
- `sample_data_hash`: Hash of the sample data
- `data_type`: Type of data required
- `quality_threshold`: Minimum quality threshold for contributions
- `deadline`: Deadline timestamp
- `min_contributions`: Minimum required contributions
- `max_contributions`: Maximum allowed contributions
- `status`: Campaign status
- `service_fee`: Fee charged for campaign creation

### `CreatorCampaignStore`
- Stores all campaigns created by a specific creator.

### `CampaignRegistry`
- Maintains a global list of all campaigns and the next campaign ID.

### `Fee`
- Stores the service fee and fee collector address.

## Public Entry Functions
### `initialize_registry(admin: &signer)`
- Initializes the campaign registry.

### `create_campaign(creator: &signer, name: String, ...)`
- Creates a new campaign and stores it under the creator.
- Requires the creator to stake the reward pool in an escrow contract.

### `cancel_campaign(creator: &signer, campaign_id: u64)`
- Allows a creator to cancel an active campaign.
- Refunds the escrowed funds based on the number of verified contributions.
- Charges a cancellation fee if contributions exist.

### `finalize_campaign(creator: &signer, campaign_id: u64)`
- Finalizes a campaign if the deadline has passed and enough contributions are verified.
- Distributes escrowed funds to verified contributors.

### `submit_contribution(contributor: &signer, campaign_id: u64, data: vector<u8>)`
- Submits a contribution to a campaign.

### `update_contribution_status(_sender: &signer, campaign_id: u64, contributor_id: u64, status: u8)`
- Updates the status of a contribution.

### `accept_verified_contributions(creator: &signer, campaign_id: u64)`
- Allows the creator to accept and finalize verified contributions.

### `withdraw_creator_fee(admin: &signer, recipient: address)`
- Allows the admin to withdraw the accumulated service fees.

## View Functions
### `get_campaign_ids(): vector<u64>`
- Retrieves all campaign IDs.

### `get_creator_campaign_ids(creator_addr: address): vector<u64>`
- Retrieves all campaign IDs for a specific creator.


## Notes for Developers
- **Frontend Devs:**
  - Ensure proper UI validation before allowing campaign creation.
  - Implement contribution submission and status tracking interfaces.
  - Use the view functions to display active campaigns.


