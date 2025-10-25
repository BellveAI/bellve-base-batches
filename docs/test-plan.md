# Test Plan - Bellve Buildathon

## ⚠️ TESTNET ONLY ⚠️

This test plan is for **Base Sepolia testnet deployment ONLY**. For evaluation purposes.

---

## Overview

This document maps Foundry tests to requirements and outlines manual QA scenarios using the demo webapp.

## Foundry Tests

### Bellve.t.sol - Integration Tests

**Purpose**: End-to-end testing of core deposit and withdrawal flows.

#### Test: `testDeployment()`

**Requirement**: System components properly configured after deployment.

**What it tests**:
- Vault provisioner address set correctly
- NFT ownership transferred to provisioner
- USDC token marked as supported

**Expected outcome**: All assertions pass.

---

#### Test: `testDepositFlow()`

**Requirement**: Users can request deposits and NFTs are minted.

**What it tests**:
- User approves USDC
- User calls requestDeposit()
- DepositRequest stored correctly
- NFT auto-minted on first deposit
- Pending deposit tracked on NFT

**Expected outcome**:
- Deposit request created with correct parameters
- NFT balanceOf user = 1
- Pending deposit = deposit amount

**Maps to requirements**:
- User deposit request acceptance
- NFT minting
- Pending balance tracking

---

#### Test: `testBatchDepositResolution()`

**Requirement**: Operator can submit and resolve batches, distributing shares fairly.

**What it tests**:
- Multiple users request deposits
- Operator submits batch with all deposits
- Operator resolves batch with share distribution
- Shares credited to users' NFTs
- Pending deposits cleared

**Expected outcome**:
- User1 balance = 100e18 shares
- User2 balance = 200e18 shares
- Pending deposits = 0 for both

**Maps to requirements**:
- Batch aggregation
- Batch resolution
- Share distribution
- Balance updates

---

#### Test: `testWithdrawalFlow()`

**Requirement**: Users can request withdrawals and shares are debited immediately.

**What it tests**:
- User has shares (via previous deposit)
- User requests withdrawal
- WithdrawalRequest stored correctly
- Shares debited from NFT immediately
- Pending withdrawal tracked

**Expected outcome**:
- Withdrawal request created
- User balance reduced by withdrawal amount
- Pending withdrawal = withdrawal shares

**Maps to requirements**:
- User withdrawal request acceptance
- Immediate share debit
- Pending withdrawal tracking

---

#### Test: `testAccessControl()`

**Requirement**: Only authorized roles can perform privileged operations.

**What it tests**:
- Random user cannot submit batches (reverts)
- Operator can submit batches
- Role-based access works correctly

**Expected outcome**:
- Unauthorized calls revert
- Authorized calls succeed

**Maps to requirements**:
- Role-based access control
- Security enforcement

---

### ProvisionerAccess.t.sol - Security Tests

**Status**: To be implemented

**Purpose**: Comprehensive role enforcement testing.

#### Planned Tests:

1. `testOnlyAdminCanGrantRoles()`
   - Only DEFAULT_ADMIN_ROLE can grant OPERATOR_ROLE
   - Random users cannot grant roles

2. `testOnlyAdminCanConfigureTokens()`
   - Only admin can call configureToken()
   - Token configuration changes rejected from non-admin

3. `testOnlyOperatorCanSubmitBatches()`
   - Only OPERATOR_ROLE can submit batches
   - Random users blocked

4. `testOnlyOperatorCanResolveBatches()`
   - Only OPERATOR_ROLE can resolve batches
   - Batch resolution restricted

5. `testAdminCanRevokeOperator()`
   - Admin can revoke OPERATOR_ROLE
   - Revoked operator cannot submit batches

---

### Accounting.t.sol - Invariant Tests

**Status**: To be implemented

**Purpose**: Test accounting invariants and edge cases.

#### Planned Tests:

1. `testSharesMintedEqualsDistributed()`
   - Total shares in batch = sum of individual shares
   - Conservation of shares

2. `testTokenConservation()`
   - Tokens in = tokens accounted for
   - No tokens lost or created

3. `testPendingBalanceAccuracy()`
   - Pending deposits sum to batch total
   - Pending withdrawals sum to batch total
   - Cleared after resolution

4. `testMultipleBatchWindows()`
   - Deposits in different windows don't interfere
   - Batch window isolation

5. `testResolveOnlyOnce()`
   - Cannot resolve same batch twice
   - AlreadyResolved error thrown

6. `testFuzz_MultipleUsers(uint8 userCount, uint256[] amounts)`
   - Fuzz test with varying users and amounts
   - System remains consistent

---

## Manual QA Scenarios

These scenarios use the demo webapp for end-to-end testing.

### Scenario 1: Single User Deposit & Withdrawal

**Actors**: 1 user, 1 operator, 1 admin

**Steps**:
1. User connects wallet to demo
2. User mints 1000 USDC
3. User approves USDC spending
4. User requests deposit of 100 USDC
5. Verify NFT minted (check balance)
6. Verify pending deposit = 100 USDC
7. Operator submits batch with user's deposit
8. Admin resolves MockGtUSDa deposit
9. Operator resolves batch, gives user 100 shares
10. Verify user balance = 100 shares
11. Verify pending deposit = 0
12. User requests withdrawal of 50 shares
13. Verify user balance = 50 shares (immediate debit)
14. Verify pending withdrawal = 50 shares
15. Operator submits withdrawal batch
16. Admin resolves MockGtUSDa redeem
17. Operator distributes 50 USDC to user
18. Verify user received ~50 USDC
19. Verify pending withdrawal = 0

**Expected outcome**: Full cycle works, balances accurate.

---

### Scenario 2: Multiple Users, Single Batch

**Actors**: 3 users, 1 operator, 1 admin

**Steps**:
1. User1 deposits 100 USDC
2. User2 deposits 200 USDC
3. User3 deposits 300 USDC
4. Operator submits batch with all 3 deposits (600 USDC total)
5. Admin resolves MockGtUSDa (600 USDC → ~600 gtUSDa)
6. Operator resolves batch, distributes shares proportionally:
   - User1: 100 shares
   - User2: 200 shares
   - User3: 300 shares
7. Verify all balances correct
8. All users request partial withdrawals
9. Operator processes withdrawal batch
10. Verify all users receive correct USDC amounts

**Expected outcome**: Batch processing handles multiple users correctly.

---

### Scenario 3: Multiple Batch Windows

**Actors**: 2 users, 1 operator

**Steps**:
1. User1 deposits in batch window T0
2. Wait for batch window to advance (or simulate)
3. User2 deposits in batch window T1
4. Operator submits batch T0 (User1 only)
5. Operator submits batch T1 (User2 only)
6. Resolve both batches independently
7. Verify both users receive shares
8. Verify batches don't interfere

**Expected outcome**: Batch windows properly isolated.

---

### Scenario 4: Access Control

**Actors**: 1 admin, 1 operator, 1 unauthorized user

**Steps**:
1. Admin grants OPERATOR_ROLE to operator address
2. Operator can see and use Batch Processor tab
3. Unauthorized user connects wallet
4. Unauthorized user cannot see Batch Processor (or sees disabled)
5. If unauthorized user tries batch operation, transaction reverts
6. Admin revokes OPERATOR_ROLE from operator
7. Operator can no longer submit batches
8. Admin re-grants role
9. Operator can submit batches again

**Expected outcome**: Access control enforced in UI and contracts.

---

### Scenario 5: Edge Cases

**Test A: Minimum Amounts**
- Deposit 1 wei USDC
- Verify system handles gracefully

**Test B: Maximum Amounts**
- Deposit large amount (e.g., 1,000,000 USDC)
- Verify no overflow

**Test C: Expired Deadline**
- Request deposit with short deadline
- Wait for expiration
- Verify operator can still process (or not, depending on design)

**Test D: Insufficient Balance**
- User tries to withdraw more shares than they have
- Verify transaction reverts

**Test E: Empty Batch**
- Operator tries to submit empty batch
- Verify EmptyArray error

---

## Performance Testing

**Note**: Not critical for buildathon but good to note.

### Gas Usage

Measure gas for typical operations:
- User deposit request: ~150k gas
- User withdrawal request: ~100k gas
- Operator submit batch (10 deposits): ~500k gas
- Operator resolve batch (10 deposits): ~800k gas

### Scalability

Test with increasing batch sizes:
- 1 deposit
- 10 deposits
- 50 deposits
- 100 deposits

Measure:
- Gas cost (should scale linearly)
- Transaction time
- Success rate

---

## Automated Testing (CI)

### Contracts CI (`.github/workflows/contracts-ci.yml`)

Runs on every push/PR:
1. Format check: `forge fmt --check`
2. Build: `forge build`
3. Test: `forge test`
4. Gas snapshot: `forge snapshot`

### Indexer CI (`.github/workflows/indexer-ci.yml`)

Runs on every push/PR:
1. Install deps: `pnpm install`
2. Type check: `tsc --noEmit`
3. Build: `pnpm build`
4. Test: `pnpm test`

### Demo CI (`.github/workflows/demo-ci.yml`)

Runs on every push/PR:
1. Install deps: `pnpm install`
2. Lint: `pnpm lint`
3. Type check: `tsc --noEmit`
4. Build: `pnpm build`

---

## Test Coverage Goals

- **Contracts**: 80%+ line coverage
- **Indexer**: 70%+ (event handlers)
- **Demo**: 60%+ (UI components)

## Known Limitations (Testnet)

These are acceptable for the buildathon but would need addressing for production:

1. No oracle price feeds (using mocks)
2. No rate limiting
3. No MEV protection
4. Single admin (no multi-sig)
5. No timelock on admin functions
6. No circuit breakers
7. No formal audit

---

## Sign-off Checklist

Before submission:

- [ ] All Foundry tests pass
- [ ] Manual Scenario 1 completed successfully
- [ ] Manual Scenario 2 completed successfully
- [ ] Access control verified
- [ ] No critical bugs in demo
- [ ] Gas usage reasonable
- [ ] Contracts verified on Basescan
- [ ] Indexer processing events
- [ ] Documentation complete

---

**Remember**: TESTNET ONLY - For evaluation purposes - No warranties or incentives

