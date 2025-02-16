# Subscription Module Documentation

## Overview
The `subscription.move` module is responsible for handling user subscriptions within the Tidmat ecosystem. It allows users to:
- Subscribe to different subscription tiers (Basic, Pro, Enterprise)
- Renew their subscriptions
- Upgrade to a higher tier
- Check subscription status

This module interacts with the `treasury.move` module for handling payments.

## Subscription Tiers & Pricing
| Tier        | Monthly Cost (Tokens) | Yearly Cost (Tokens) |
|------------|----------------------|----------------------|
| Basic      | 10                   | 120                  |
| Pro        | 25                   | 300                  |
| Enterprise | 100                  | 1200                 |

## Subscription Durations
- **Monthly:** 30 days (2592000 seconds)
- **Yearly:** 365 days (31536000 seconds)

---

## Functions
### **1. subscribe(subscriber: &signer, tier: u8, duration: u64)**
**Description:**
- Allows a user to subscribe to a tier for a specified duration.
- Processes payment through the `treasury.move` module.
- Stores subscription details on-chain.

**Valid Tiers:**
- `1` → Basic
- `2` → Pro
- `3` → Enterprise

**Parameters:**
- `subscriber`: The user's wallet address
- `tier`: The subscription tier (1, 2, or 3)
- `duration`: The duration in seconds (e.g., `2592000` for 1 month)

**Errors:**
- `EINVALID_SUBSCRIPTION_TIER (1)`: If the tier is invalid.
- `ESUBSCRIPTION_ALREADY_EXISTS (2)`: If the user already has an active subscription.

**Usage:**
```move
subscribe(&signer, 2, PERIOD_MONTHLY); // Subscribes to Pro for 1 month
```

---
### **2. renew_subscription(subscriber: &signer, duration: u64)**
**Description:**
- Renews an existing subscription for a given duration.

**Parameters:**
- `subscriber`: The user's wallet address
- `duration`: Duration to extend the subscription

**Errors:**
- `ESUBSCRIPTION_NOT_FOUND (3)`: If the user does not have a subscription.

**Usage:**
```move
renew_subscription(&signer, PERIOD_YEARLY); // Renews for 1 year
```

---
### **3. upgrade_subscription(subscriber: &signer, new_tier: u8)**
**Description:**
- Upgrades an existing subscription to a higher tier.
- The user pays only for the upgrade difference based on remaining time.

**Parameters:**
- `subscriber`: The user's wallet address
- `new_tier`: The new tier to upgrade to

**Errors:**
- `ESUBSCRIPTION_NOT_FOUND (3)`: If the user does not have a subscription.
- `EINVALID_SUBSCRIPTION_TIER (1)`: If the new tier is not valid or lower than the current one.

**Usage:**
```move
upgrade_subscription(&signer, 3); // Upgrades to Enterprise
```

---
### **4. is_subscription_active(subscriber_address: address): bool**
**Description:**
- Checks if a user’s subscription is active.

**Parameters:**
- `subscriber_address`: The address of the user

**Returns:**
- `true` if the subscription is active
- `false` if not

**Usage:**
```move
let active = is_subscription_active(@user_address);
```

---
### **5. get_subscription_tier(subscriber_address: address): u8**
**Description:**
- Retrieves the user's current subscription tier.

**Errors:**
- `ESUBSCRIPTION_NOT_FOUND (3)`: If the user does not have a subscription.

**Usage:**
```move
let tier = get_subscription_tier(@user_address);
```

---
### **6. get_subscription_end_time(subscriber_address: address): u64**
**Description:**
- Returns the expiration timestamp of a user’s subscription.

**Errors:**
- `ESUBSCRIPTION_NOT_FOUND (3)`: If the user does not have a subscription.

**Usage:**
```move
let end_time = get_subscription_end_time(@user_address);
```

---

## Payment Handling
All payment transactions are processed using `treasury.move`. The function `treasury::process_payment()` is called inside `subscribe()`, `renew_subscription()`, and `upgrade_subscription()`.

Example payment flow:
```move
treasury::process_payment(&signer, cost);
```

---
## Integration Guide
### **For Frontend Developers**
- Use the exposed entry functions (`subscribe`, `renew_subscription`, `upgrade_subscription`) to initiate transactions.
- Use the `is_subscription_active` function to check if a user’s subscription is active before showing premium features.
- Retrieve subscription details with `get_subscription_tier` and `get_subscription_end_time`.

---

## TODOs & Placeholders
- [ ] **Support refunds for canceled subscriptions.**
- [ ] **Allow users to pause/resume subscriptions.**
- [ ] **Add event logging for subscription lifecycle tracking.**

---
## Error Handling
| Error Code | Description |
|-----------|-------------|
| 1 | Invalid subscription tier |
| 2 | Subscription already exists |
| 3 | Subscription not found |
| 4 | Subscription expired |
| 5 | Invalid payment |
| 6 | Not authorized |

---
## Notes
- The subscription module is designed to be extendable.
- Ensure you have enough tokens in the treasury before subscribing.
- Upgrade costs are calculated dynamically based on remaining subscription time.

---

## Contact
For further inquiries, please reach out to the Tidmat development team.


