# Inventory-Management_smartcontract

A highly gas-efficient and secure **Inventory Management Smart Contract** built on Solidity (v0.8.x). It enables owners and authorized users to manage item stock, perform sales, track low inventory, and update product details while optimizing for gas savings and security.

---

## 🚀 Features

- **Gas Optimization:**
  - Custom `error` types instead of `require` strings
  - Packed `structs` to reduce storage costs
  - Unchecked arithmetic where safe
  - Batch processing (add, sell, authorize users)

- **Inventory Operations:**
  - Add items (individually or in batch)
  - Sell items (individually or in batch)
  - Update item details
  - Replenish stock
  - Delete items
  - View out-of-stock and low-stock items

- **Access Control:**
  - Role-based authorization (owner and authorized users)
  - Batch user authorization
  - Ownership transfer
  - Contract pause/unpause

- **Events & Auditing:**
  - Emits events on item addition, sale, update, stock change, and access control changes for easy tracking

---

## 🔐 Access Roles

| Role             | Capabilities                                                                      |
|------------------|-----------------------------------------------------------------------------------|
| Owner            | Full control, can authorize users, manage contract, transfer ownership            |
| Authorized Users | Can add/sell/update inventory, replenish stock, and query inventory               |
| Others           | Restricted access                                                                 |

---

## 🧱 Data Structures

### `Item` Struct
```solidity
struct Item {
    uint128 quantity;
    uint128 price;
    string itemName;
    address addedBy;
    uint32 timestamp;
    bool exists;
}
```

---

## ⚙️ Core Functions

### Inventory Management
- `addItem(string, uint128, uint128)`
- `addItems(string[], uint128[], uint128[])`
- `sellItem(uint32, uint128)`
- `sellItems(uint32[], uint128[])`
- `updateItem(uint32, string, uint128, uint128)`
- `replenishStock(uint32, uint128)`
- `removeItem(uint32)`

### Query Functions
- `getItem(uint32)`
- `getTotalItems()`
- `isOutOfStock(uint32)`
- `checkLowStock(uint128 threshold, uint32 start, uint32 limit)`

### Access Control
- `authorizeUser(address)`
- `batchAuthorizeUsers(address[])`
- `deauthorizeUser(address)`
- `transferOwnership(address)`

### Emergency Functions
- `pauseContract()`
- `unpauseContract()`

---

## 🛠 Deployment

1. Ensure you're using **Solidity ^0.8.0**
2. Deploy using Remix, Hardhat, Foundry, or Truffle
3. Set the contract owner on deployment (`msg.sender`)

---

## 📦 Optimization Highlights

- **Custom Errors**: ~50% gas saving vs string `require`
- **Tight Packing**: Efficient use of storage slots
- **Unchecked Blocks**: Reduces gas where overflow is impossible
- **Low-cost Lookups**: Minimal read operations and filtered events

---

## 📄 License

This project is licensed under the [MIT License](./LICENSE).
