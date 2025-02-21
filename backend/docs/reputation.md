# Reputation Module Documentation

## Overview
The `tidmat::reputation` module implements a contributor reputation system that tracks contributions, assigns reputation and quality scores, and awards badges based on user performance. This module enables:
- Creating contributor profiles.
- Updating reputation and quality scores.
- Awarding badges based on contribution performance.
- Retrieving user scores and contribution statistics.

## Smart Contract Structure
### Data Structures
#### 1. **Badge**
```move
struct Badge has store, drop, copy {
    badge_type: u8,
    earned_at: u64,
    metadata: String
}
```
- Represents an achievement earned by a contributor.
- Stores badge type, timestamp of acquisition, and metadata.

#### 2. **ContributorProfile**
```move
struct ContributorProfile has key {
    reputation_score: u64,
    quality_score: u64,
    total_contributions: u64,
    successful_contributions: u64,
    badges: vector<Badge>
}
```
- Stores reputation and quality scores, contribution statistics, and earned badges.

#### 3. **ReputationConfig**
```move
struct ReputationConfig has key {
    admin: address,
    min_score_for_badges: vector<u64>,
    score_weights: vector<u64>
}
```
- Stores configuration settings for the reputation system, including badge thresholds and score weights.

### Error Codes
- `EPROFILE_ALREADY_EXISTS` (1): Profile creation attempted for an existing user.
- `EPROFILE_NOT_FOUND` (2): Profile retrieval attempted for a non-existent user.
- `EBADGE_ALREADY_OWNED` (3): User already owns a requested badge.
- `EINVALID_SCORE_UPDATE` (4): Invalid reputation or quality score update.
- `ENOT_AUTHORIZED` (5): Unauthorized admin operation.
- `EINVALID_BADGE_TYPE` (6): Invalid badge type requested.

### Badge Types
| Badge Name                    | Type Value |
|--------------------------------|------------|
| Novice Contributor            | 1          |
| Experienced Contributor        | 2          |
| Expert Contributor             | 3          |
| Quality Master                 | 4          |
| Consistent Contributor         | 5          |

## Entry Functions
### 1. **initialize_reputation_system**
```move
public entry fun initialize_reputation_system(
    admin: &signer,
    min_scores: vector<u64>,
    weights: vector<u64>
)
```
- Initializes the reputation system with admin privileges.
- Requires minimum scores and score weights as inputs.

### 2. **create_profile**
```move
public entry fun create_profile(account: &signer)
```
- Creates a new contributor profile with initial scores set to zero.

### 3. **update_reputation**
```move
public entry fun update_reputation(
    admin: &signer,
    contributor_address: address,
    score_change: u64,
    quality_change: u64
) acquires ContributorProfile, ReputationConfig
```
- Updates a contributor's reputation and quality scores.
- Requires admin privileges.

### 4. **record_contribution**
```move
public entry fun record_contribution(
    contributor_address: address,
    was_successful: bool
) acquires ContributorProfile
```
- Updates total and successful contributions for a user.
- Awards badges if contribution thresholds are met.

### 5. **award_custom_badge**
```move
public entry fun award_custom_badge(
    admin: &signer,
    contributor_address: address,
    badge_type: u8,
    metadata: String
) acquires ContributorProfile, ReputationConfig
```
- Assigns a badge to a contributor.
- Requires admin privileges.

## View Functions
### 1. **get_reputation_score**
```move
public fun get_reputation_score(contributor_address: address): u64 acquires ContributorProfile
```
- Returns the reputation score of a contributor.

### 2. **get_quality_score**
```move
public fun get_quality_score(contributor_address: address): u64 acquires ContributorProfile
```
- Returns the quality score of a contributor.

### 3. **get_contribution_stats**
```move
public fun get_contribution_stats(contributor_address: address): (u64, u64) acquires ContributorProfile
```
- Returns total and successful contributions.

### 4. **has_badge**
```move
public fun has_badge(contributor_address: address, badge_type: u8): bool acquires ContributorProfile
```
- Checks if a contributor owns a specific badge.

### 5. **get_all_badges**
```move
public fun get_all_badges(contributor_address: address): vector<Badge> acquires ContributorProfile
```
- Retrieves all badges owned by a contributor.

## Internal Functions
### **check_and_award_badges**
```move
fun check_and_award_badges(profile: &mut ContributorProfile)
```
- Awards badges based on contribution thresholds.

### **has_badge_internal**
```move
fun has_badge_internal(profile: &ContributorProfile, badge_type: u8): bool
```
- Checks if a contributor has a specific badge.

### **award_badge**
```move
fun award_badge(profile: &mut ContributorProfile, badge_type: u8, metadata: String)
```
- Assigns a badge to a contributor.


## How Frontend Developers Can Use This
### 1. **Profile Creation**
When a user registers, invoke:
```move
create_profile(user_signer)
```

### 2. **Updating Reputation**
Admins can update a contributor's score using:
```move
update_reputation(admin_signer, contributor_address, reputation_increase, quality_increase)
```

### 3. **Retrieving Scores**
Use view functions to fetch scores:
```move
get_reputation_score(contributor_address)
get_quality_score(contributor_address)
get_contribution_stats(contributor_address)
```

### 4. **Handling Badges**
Check and retrieve badges:
```move
has_badge(contributor_address, badge_type)
get_all_badges(contributor_address)
```

### 5. **Awarding Custom Badges**
Admins can manually award a badge:
```move
award_custom_badge(admin_signer, contributor_address, badge_type, "Custom achievement metadata")
```

## Conclusion
The `tidmat::reputation` module provides a flexible and extensible reputation system for tracking contributions, reputation scores, and awarding badges.