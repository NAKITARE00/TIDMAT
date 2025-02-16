# Campaign Module Documentation

## Overview
The `campaign.move` module powers the campaign system within the Tidmat ecosystem. It allows creators to initiate data collection campaigns, stake reward pools, manage contributor submissions, and distribute rewards upon successful verification.

## Features
- **Campaign Creation**: Enables creators to launch campaigns and set staking requirements.
- **Contribution Submission**: Allows contributors to submit data for review.
- **Verification & Acceptance**: Creators verify contributions and accept valid submissions.
- **Reward Distribution**: Distributes rewards to successful contributors.
- **Campaign Cancellation**: Allows creators to cancel campaigns under specific conditions.
- **Campaign Inquiry**: Provides views to retrieve campaign details and status.

## Data Structures
### `Campaign`
A struct that represents a campaign:
```move
struct Campaign has key {
    creator: address,
    reward_pool: u64,
    total_contributions: u64,
    verified_contributions: u64,
    active: bool
}
```
- `creator`: The address of the campaign creator.
- `reward_pool`: The total amount staked for rewards.
- `total_contributions`: The number of contributions received.
- `verified_contributions`: The number of accepted contributions.
- `active`: Indicates if the campaign is active.

### `Contribution`
A struct that represents a contribution:
```move
struct Contribution has key {
    contributor: address,
    campaign_id: u64,
    accepted: bool
}
```
- `contributor`: The address of the contributor.
- `campaign_id`: The ID of the associated campaign.
- `accepted`: Whether the contribution is accepted or not.

## Functions
### `create_campaign(creator: &signer, reward_pool: u64) acquires Campaign`
Initializes a new campaign and stakes the reward pool.

### `submit_contribution(contributor: &signer, campaign_id: u64) acquires Contribution`
Allows users to submit data to a campaign.

### `verify_contribution(creator: &signer, contributor: address, campaign_id: u64) acquires Campaign, Contribution`
Marks a contribution as accepted if valid.

### `distribute_rewards(creator: &signer, campaign_id: u64) acquires Campaign`
Distributes rewards among accepted contributors.

### `cancel_campaign(creator: &signer, campaign_id: u64) acquires Campaign`
Allows a creator to cancel a campaign, with refund conditions:
- If contributions exist, a 10% fee is deducted.
- If no contributions exist, a full refund is processed.

### `get_campaign_details(campaign_id: u64) acquires Campaign` (View Function)
Fetches details of a campaign, including status and rewards.

### `get_user_contributions(user: address) acquires Contribution` (View Function)
Returns all contributions made by a user.

## Usage Guide
### Frontend Integration
1. **Campaign Creation:** Call `create_campaign(creator, reward_pool)` when a user wants to launch a campaign.
2. **Submission Flow:** Call `submit_contribution(contributor, campaign_id, data)` when a user submits data.
3. **Update Submission Status:** Update submissions using `update_contribution_status(creator, campaign_id, contributor, status)`.
4. **Reward Distribution:** After verification and all contributions are accepted, call `finalize_campaign(creator, campaign_id)`.
5. **Campaign Cancellation:** Use `cancel_campaign(creator, campaign_id)` if necessary.
6. **Data Retrieval:** Use `get_campaign_details(campaign_id)` and `get_user_contributions(user)` to fetch campaign and user data.
7. **Accept Verified Contributions:** Use `accept_verified_contributions(creator, campaign_id)` to accept all campaign contributions

## TODOs & Placeholders
- **Error Handling:** Improve error messages for invalid actions.
- **Multi-Creator Support:** Allow multiple stakeholders in a campaign.
- **Event Emissions:** Emit events for campaign creation, contributions, and payouts.

---
This documentation provides an overview of the `campaign.move` module, its functionalities, and how to integrate with it from the frontend. 🚀


