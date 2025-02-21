# Contribution Module Documentation

## Overview
The `contribution.move` module manages contributions made by users to various campaigns. It enables tracking, submission, verification, and acceptance of contributions. This document provides a detailed explanation of its functionalities, assisting frontend and backend developers in integrating and utilizing this module.

## Features
- **Submit contributions**: Users can submit contributions linked to specific campaigns.
- **Track contributions**: Contributions are stored and retrieved via a `ContributionTracker`.
- **Verify and accept contributions**: Contributions undergo a status update process from submission to verification and acceptance.
- **Retrieve contributions**: Provides methods to query contributions based on campaign ID, contributor ID, or status.

## Data Structures

### `Contribution`
Represents an individual contribution to a campaign.
```move
struct Contribution has key, store, drop, copy {
    contribution_id: u64,
    campaign_id: u64,
    contributor: address,
    data: vector<u8>,
    status: u8
}
```

### `ContributionTracker`
Tracks all contributions and maintains a counter for the next contribution ID.
```move
struct ContributionTracker has key, store, copy {
    contributions: vector<Contribution>,
    next_contribution_id: u64
}
```

## Constants
```move
const CONTRIBUTION_STATUS_SUBMITTED: u8 = 1;
const CONTRIBUTION_STATUS_VERIFIED: u8 = 2;
const CONTRIBUTION_STATUS_ACCEPTED: u8 = 3;
const CONTRIBUTION_STATUS_REJECTED: u8 = 4;
```

## Functions

### `init_contribution_module`
Initializes the contribution tracking system.
```move
public fun init_contribution_module(c: &signer)
```
- **Usage**: Should be called once at module deployment.

### `submit_a_contribution`
Submits a contribution for a campaign.
```move
public fun submit_a_contribution(contributor: &signer, campaign_id: u64, data: vector<u8>) acquires ContributionTracker
```
- **Validations**:
  - Data must not be empty.
  - A contributor cannot submit multiple contributions to the same campaign.
- **Frontend Usage**:
  - Call this function when a user submits a contribution.

### `get_campaign_contributions`
Retrieves contribution IDs for a given campaign.
```move
public fun get_campaign_contributions(campaign_id: u64): vector<u64> acquires ContributionTracker
```
- **Backend Usage**:
  - Use this function to fetch all contribution IDs linked to a campaign.

### `get_contributor_details`
Fetches contribution details by contributor ID.
```move
public fun get_contributor_details(contributor_id: u64): (u64, address, vector<u8>, u8) acquires ContributionTracker
```
- **Returns**: (Campaign ID, Contributor Address, Data, Status)
- **Frontend Usage**:
  - Fetch user contribution details for display.

### `update_contrib_status`
Updates the status of a contribution.
```move
public fun update_contrib_status(status: u8, contrib_id: u64, campaign_id: u64) acquires ContributionTracker
```
- **Validations**:
  - Status must be `VERIFIED` or `REJECTED`.
- **Backend Usage**:
  - Admin or verification process can invoke this function.

### `accept_campaign_contributions`
Marks verified contributions as accepted for a specific campaign.
```move
public fun accept_campaign_contributions(campaign_id: u64) acquires ContributionTracker
```
- **Usage**: Final step in contribution verification.

### `get_contribution_tracker`
Returns all contributions and separately lists verified contributions for a campaign.
```move
public fun get_contribution_tracker(campaign_id: u64): (vector<Contribution>, vector<Contribution>) acquires ContributionTracker
```

## Integration Guide
### Frontend
- Use `submit_a_contribution` to allow users to submit contributions.
- Call `get_campaign_contributions` to display user contributions for a campaign.
- Utilize `get_contributor_details` for detailed contribution information.

## Conclusion
This module provides a structured way to handle contributions in a decentralized system. 