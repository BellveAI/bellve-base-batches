# Bellve Buildathon Architecture

## ⚠️ TESTNET PROTOTYPE DISCLAIMER ⚠️

This document describes a **prototype system for Base Sepolia testnet ONLY**. This is NOT production-ready code. Implementation details are subject to change without notice. No warranties, incentives, or expectations of profit. For evaluation purposes only.

---

## System Overview

Bellve is an innovative DeFi vault system that solves the challenge of asynchronous yield-bearing asset interactions through sophisticated batching mechanisms. The system enables users to deposit assets into yield-generating strategies without waiting for slow external protocols to complete operations.

### Core Innovation: Asynchronous Batching

Traditional DeFi vaults require users to wait for each operation to complete before receiving shares/tokens. Bellve aggregates multiple user requests into time-windowed batches, processes them asynchronously with external yield protocols, and distributes shares fairly based on resolved exchange rates.

---

## Architecture Diagram

```
┌────────────────────────────────────────────────────────────────────┐
│                         USERS                                       │
│  (Deposits, Withdrawals, Balance Queries)                          │
└──────────────────────┬─────────────────────────────────────────────┘
                       │
                       ▼
         ┌─────────────────────────────┐
         │   BellveProvisioner         │
         │   ─────────────────────     │
         │   • Request Handling        │
         │   • Batch Windowing         │
         │   • Access Control          │
         │   • NFT Coordination        │
         └────────┬────────────────────┘
                  │
      ┌───────────┼───────────┬──────────────┐
      │           │           │              │
      ▼           ▼           ▼              ▼
┌──────────┐ ┌────────┐ ┌─────────────┐ ┌────────────┐
│ Address  │ │ Bellve │ │   Account   │ │   Price    │
│ Registry │ │ Vault  │ │     NFT     │ │ Calculator │
└──────────┘ └────────┘ └──────┬──────┘ └────────────┘
                                │
                  ┌─────────────┴──────────────┐
                  │   Soulbound ERC721         │
                  │   • Per-profile balances   │
                  │   • Pending operations     │
                  │   • Lifetime statistics    │
                  └────────────────────────────┘

External Integration:
         ┌──────────────────────┐
         │   MockGtUSDa Vault   │
         │   ─────────────────  │
         │   • Async deposits   │
         │   • Async redeems    │
         │   • Request pattern  │
         └──────────┬───────────┘
                    │
      ┌─────────────┴──────────────┐
      │  Simulates Aera-style      │
      │  async yield operations    │
      └────────────────────────────┘

Indexing & Analytics:
         ┌──────────────────────┐
         │   Sentio Indexer     │
         │   ──────────────── │
         │   • Event listeners  │
         │   • Entity storage   │
         │   • Metrics/counters │
         │   • Dashboard data   │
         └──────────────────────┘

Demo & Automation:
         ┌──────────────────────┐
         │   React Demo WebApp  │
         │   ──────────────── │
         │   • User dashboard   │
         │   • Batch processor  │
         │   • Mock processor   │
         │   • Access control   │
         └──────────────────────┘
```

---

## Component Deep Dive

### 1. BellveProvisioner

**Purpose**: Central orchestrator for all user operations and batch processing.

**Key Features**:
- **Access Control**: OpenZeppelin AccessControl with two roles:
  - `DEFAULT_ADMIN_ROLE`: Full system control
  - `OPERATOR_ROLE`: Batch processing (for indexers/automation)
- **Batch Windowing**: 1-hour windows for aggregating requests
- **Event Emissions**: Rich events for off-chain indexing
- **Safety**: ReentrancyGuard, SafeERC20, comprehensive validation

**User Flow - Deposits**:
```
1. User calls requestDeposit(token, amount, minUnitsOut, deadline, riskProfile)
2. Tokens transferred from user to provisioner
3. DepositRequest stored with batch window assignment
4. NFT minted if user doesn't have one
5. Pending deposit recorded on NFT
6. DepositRequested event emitted
```

**Operator Flow - Batch Resolution**:
```
1. Operator calls submitBatchDeposits(window, depositHashes[])
2. System validates all deposits belong to window
3. BatchDeposit created and BatchDepositSubmitted event emitted
4. Operator calls resolveBatchDeposits(window, depositHashes[], shares[])
5. Shares credited to each user's NFT
6. Pending deposits cleared
7. DepositResolved events emitted per user
```

**Key Storage**:
- `depositRequests`: depositHash → DepositRequest
- `batchDeposits`: batchWindow → BatchDeposit
- `batchWindowDeposits`: batchWindow → depositHash[]
- Similar structures for withdrawals

### 2. BellveAccountNFT

**Purpose**: Soulbound ERC721 tracking user balances, pending operations, and lifetime stats.

**Key Features**:
- **Soulbound**: Cannot be transferred (except minting)
- **Multi-Profile**: Supports risk profiles 0-2 for different strategies
- **Balance Tracking**: Per-profile share balances
- **Pending Operations**: Tracks deposits/withdrawals in progress
- **Metadata**: Member since, total deposited/withdrawn, last activity

**Storage Per Token**:
```solidity
struct AccountMetadata {
    uint256 memberSince;      // Timestamp of account creation
    uint256 totalDeposited;   // Lifetime deposit amount
    uint256 totalWithdrawn;   // Lifetime withdrawal amount
    uint256 lastActivity;     // Last transaction timestamp
}

// Per token, per risk profile:
balances[tokenId][riskProfile]           // Current share balance
pendingDeposits[tokenId][riskProfile]    // Pending deposit amount
pendingWithdrawals[tokenId][riskProfile] // Pending withdrawal shares
```

**NFT Lifecycle**:
1. Auto-minted on first deposit
2. Updated on every deposit resolution (shares credited)
3. Updated on withdrawal request (shares debited immediately)
4. Updated on withdrawal resolution (pending cleared)
5. Never burned or transferred

### 3. BellveVault

**Purpose**: Simplified vault coordinator for tracking supported tokens.

**Key Features**:
- Non-ERC20 design (balances tracked in NFT)
- Token support management
- Event coordinator for transparency
- Provisioner authorization

**Design Rationale**:
Separates token coordination from balance tracking, allowing the NFT to be the source of truth for user balances while the vault handles token approvals and events.

### 4. AddressRegistry + RegistryConsumer

**Purpose**: Central registry pattern eliminating circular dependencies.

**Pattern**:
```
AddressRegistry (storage)
      ↓
RegistryConsumer (caching)
      ↓
All System Contracts
```

**Benefits**:
- Single source of truth for addresses
- Gas-efficient caching
- Easy upgrades (change registry, sync consumers)
- No circular imports

### 5. MockGtUSDa

**Purpose**: Simulates Aera-style async vault for testing.

**Async Pattern**:
```
Deposit Flow:
1. User calls requestDeposit(assets)
2. Assets transferred, depositRequest stored
3. Returns requestHash
4. [TIME PASSES - simulates async processing]
5. Someone calls resolveDeposit(requestHash)
6. Shares minted to depositor

Redeem Flow:
1. User calls requestRedeem(shares)
2. Shares burned, redeemRequest stored
3. Returns requestHash
4. [TIME PASSES]
5. Someone calls resolveRedeem(requestHash)
6. Assets transferred to redeemer
```

This pattern mimics real protocols like Aera that have asynchronous settlement.

---

## Batching Flow - Step by Step

### Deposit Batch Example

**Hour 1 (00:00-00:59): Request Phase**
```
00:15 - Alice deposits 100 USDC → depositHash1
00:30 - Bob deposits 200 USDC   → depositHash2
00:45 - Carol deposits 150 USDC → depositHash3

All assigned to batchWindow = 00:00
Total batch: 450 USDC
```

**Hour 2 (01:00+): Processing Phase**
```
01:05 - Operator submits batch:
        submitBatchDeposits(00:00, [hash1, hash2, hash3])
        → BatchDepositSubmitted event

01:10 - External yield protocol resolves (MockGtUSDa)
        → gtUSDa shares obtained

01:15 - Operator resolves batch:
        resolveBatchDeposits(00:00, [hash1, hash2, hash3], [100e18, 200e18, 150e18])
        → Alice gets 100 shares
        → Bob gets 200 shares
        → Carol gets 150 shares
        → 3x DepositResolved events
```

**Fairness**: All users in same batch get same exchange rate.

### Withdrawal Batch Example

Similar flow but in reverse:
1. Users request withdrawals (shares debited immediately)
2. Operator submits batch
3. External protocol redeems shares for tokens
4. Operator distributes tokens to users

---

## Sentio Indexer Architecture

### Entity Model

```
DepositRequestEntity
├── depositHash (ID)
├── user
├── token
├── amount
├── batchWindow
├── resolved
└── riskProfile

WithdrawalRequestEntity
├── withdrawalHash (ID)
├── user
├── shares
├── batchWindow
├── resolved
└── riskProfile

BatchDepositEntity
├── batchWindow-batchHash (ID)
├── totalAmount
├── depositCount
└── resolved

BatchWithdrawalEntity
├── batchWindow-batchHash (ID)
├── totalShares
├── withdrawalCount
└── resolved

AccountNFTStateEntity
├── user-riskProfile (ID)
├── balance
├── pendingDeposit
├── pendingWithdrawal
└── timestamp
```

### Event Processing

```
DepositRequested → Store DepositRequestEntity
                 → Increment deposit_requested counter

DepositResolved → Update resolved flag
               → Increment deposit_resolved counter

BatchDepositSubmitted → Store BatchDepositEntity
                      → Increment batch counter

Similar for withdrawals...
```

### Metrics & Analytics

Sentio automatically provides:
- Event counts over time
- User activity heatmaps
- Batch utilization rates
- Average resolution times
- Gas usage analytics

---

## Demo WebApp Architecture

### Component Structure

```
App.tsx (Main Container)
├── Web3Context (MetaMask connection)
├── HashHistoryContext (localStorage)
└── Tab Navigation
    ├── UserDashboard
    │   ├── Balance display
    │   ├── Mint USDC
    │   ├── Request Deposit
    │   └── Request Withdrawal
    ├── BatchProcessor (Operator Only)
    │   ├── Submit Deposit Batch
    │   ├── Resolve Deposit Batch
    │   ├── Submit Withdrawal Batch
    │   └── Resolve Withdrawal Batch
    ├── MockProcessor (Admin Only)
    │   ├── Resolve gtUSDa Deposits
    │   └── Resolve gtUSDa Redeems
    └── AccessControl (Admin Only)
        ├── View Roles
        ├── Grant Operator Role
        └── Revoke Roles
```

### Automation Features

- **Hash Extraction**: Auto-extracts hashes from transaction receipts
- **Hash History**: Stores recent hashes in localStorage for easy reuse
- **Role Detection**: Shows/hides features based on user's roles
- **Batch Helper**: Guides users through 3-step batch resolution:
  1. Submit batch → extract hash
  2. Resolve in MockGtUSDa
  3. Resolve batch distribution

---

## Security Considerations

### Current Implementation (Testnet)

✅ **Implemented**:
- AccessControl for role-based permissions
- ReentrancyGuard on critical functions
- SafeERC20 for token transfers
- Comprehensive input validation
- Deadline checks on requests
- Balance checks before operations

⚠️ **Missing (Required for Production)**:
- Multi-sig governance
- Timelock on admin functions
- Circuit breakers for emergencies
- Rate limiting
- Formal security audit
- Economic attack modeling
- Insurance fund
- Upgradability pattern
- Oracle price feeds (using mocks now)
- MEV protection

---

## Gas Optimization

### Batch Processing Benefits

**Without Batching**:
- 100 users deposit → 100 separate vault interactions
- Gas: ~150k per user = 15M gas total

**With Batching**:
- 100 users deposit → 1 batch submission + 1 resolution
- Gas: ~50k per user for request + ~500k batch = 5.5M gas total
- **~63% gas savings**

### Additional Optimizations

- Immutable registry reference
- Cached addresses in RegistryConsumer
- Minimal storage slots
- Efficient mappings
- Event-based off-chain queries

---

## Testing Strategy

### Foundry Tests

**Bellve.t.sol** (Integration):
- Full deposit flow
- Batch submission and resolution
- Withdrawal flow
- NFT state transitions
- Multi-user scenarios

**ProvisionerAccess.t.sol** (Security):
- Role enforcement
- Unauthorized access reverts
- Admin vs Operator permissions

**Accounting.t.sol** (Invariants):
- Shares minted = shares distributed
- Token conservation
- Pending balance accuracy

### Manual Testing (Demo Webapp)

1. Connect multiple wallets
2. Request deposits from each
3. Process batch as operator
4. Verify shares distributed correctly
5. Request withdrawals
6. Process withdrawal batch
7. Verify tokens received

---

## Deployment Architecture

```
Step 1: Deploy Core
└── AddressRegistry
    ├── BellveAccountNFT
    ├── BellveVault
    └── BellveProvisioner

Step 2: Deploy Mocks
└── MockUSDC
    ├── MockGtUSDa
    └── MockPriceCalculator

Step 3: Wire System
└── Register addresses
    ├── Transfer ownerships
    ├── Grant roles
    └── Configure tokens

Step 4: Deploy Indexer
└── Upload to Sentio

Step 5: Launch Demo
└── Start React app
```

---

## Future Enhancements (Post-Buildathon)

1. **Multi-Asset Support**: Multiple yield strategies per risk profile
2. **Dynamic Batch Windows**: Adjust based on TVL/activity
3. **Auto-Compounding**: Reinvest yields automatically
4. **Governance**: DAO control over parameters
5. **L2 Bridge**: Cross-chain deposits
6. **NFT Metadata**: On-chain SVG generation
7. **Referral System**: Share-based rewards
8. **Emergency Pause**: Circuit breaker implementation

---

## Alignment with RFC-004 (if applicable)

[This section would describe how the system aligns with any Bellve RFC-004 specifications]

---

## References

- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Sentio Documentation](https://docs.sentio.xyz/)
- [Foundry Book](https://book.getfoundry.sh/)
- [Base Network](https://docs.base.org/)
- [EIP-721 (NFT)](https://eips.ethereum.org/EIPS/eip-721)
- [EIP-5192 (Soulbound)](https://eips.ethereum.org/EIPS/eip-5192)

---

**Remember**: This is a TESTNET PROTOTYPE for evaluation only. Not production-ready. Subject to change. No warranties or incentives.

