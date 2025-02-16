# Treasury Module Documentation

## Overview
The `treasury.move` module is responsible for handling financial transactions within the Tidmat ecosystem. It manages a central treasury that holds funds, processes payments for subscriptions, and allows authorized administrators to withdraw funds.

## Features
- **Module Initialization**: Initializes the treasury and assigns an admin.
- **Payment Processing**: Handles payments from users for subscription services.
- **Fund Withdrawal**: Allows admins to withdraw funds from the treasury.
- **Balance Inquiry**: Fetches the current treasury balance.

## Data Structures
### `Treasury`
A global resource that stores treasury information:
```move
struct Treasury has key {
    bal: u64,
    store: Object<fungible_asset::FungibleStore>
}
```
- `bal`: The balance of the treasury.
- `store`: An object reference to the fungible asset store.

### `Admin`
Defines an admin who can withdraw funds:
```move
struct Admin has key {
    addr: address
}
```
- `addr`: Address of the admin.

## Functions
### `init_module(admin: &signer)`
Initializes the treasury module with an admin.

### `process_payment(payer: &signer, amount: u64) acquires Treasury`
Handles payments from users, transferring funds to the treasury.

### `withdraw_funds(admin: &signer) acquires Admin, Treasury`
Allows the admin to withdraw all funds from the treasury.

### `get_treasury_bal() acquires Treasury` (View Function)
Returns the current balance of the treasury.

### `assert_admin(account: &signer) acquires Admin`
Checks if the signer is the authorized admin.

### `get_token_metadata()`
Returns the token metadata object.

## Usage Guide
### Setting Up the Treasury
1. Deploy the `treasury.move` module.
2. Call `init_module(admin: &signer)` to initialize the treasury.
3. Ensure the `Admin` struct is correctly assigned.

### Processing Payments
1. Call `process_payment(payer: &signer, amount: u64)` to transfer funds.
2. The payer must have enough balance in their wallet.

### Checking Treasury Balance
- Use `get_treasury_bal()` to get the current balance.

### Withdrawing Funds
- Only the assigned admin can call `withdraw_funds(admin: &signer)` to withdraw funds.

## TODOs & Placeholders
- **Custom Error Handling**: Improve error messages.
- **Multi-Admin Support**: Consider allowing multiple admins for fund withdrawals.
- **Event Emissions**: Emit events for payments and withdrawals.

---
This documentation provides an overview of the `treasury.move` module, its functionalities, and usage instructions. 🚀


