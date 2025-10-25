# Indexer Documentation - Bellve Buildathon

## ⚠️ TESTNET ONLY ⚠️

This indexer is for **Base Sepolia testnet ONLY**. For evaluation purposes with no warranties.

---

## Overview

The Bellve Buildathon indexer uses [Sentio](https://sentio.xyz) to process on-chain events from the BellveProvisioner contract and store them in a queryable database.

## Architecture

```
Base Sepolia Chain
      ↓ (events)
BellveProvisioner Contract
      ↓ (DepositRequested, WithdrawalRequested, etc.)
Sentio Processor
      ↓ (parse & transform)
Entity Store (PostgreSQL)
      ↓ (query)
Sentio Dashboard / API
```

## Entity Model

### DepositRequestEntity

Tracks individual deposit requests from users.

| Field | Type | Description |
|-------|------|-------------|
| id | string | depositHash (unique) |
| user | string | User address (lowercase) |
| token | string | Token address (lowercase) |
| amount | string | Deposit amount |
| minUnitsOut | string | Minimum units expected |
| batchWindow | int | Batch window timestamp |
| blockNumber | int | Block when created |
| timestamp | date | Timestamp when created |
| resolved | boolean | Whether resolved |
| riskProfile | int | Risk profile ID (0-2) |

### WithdrawalRequestEntity

Tracks individual withdrawal requests from users.

| Field | Type | Description |
|-------|------|-------------|
| id | string | withdrawalHash (unique) |
| user | string | User address (lowercase) |
| token | string | Token address (lowercase) |
| shares | string | Shares to redeem |
| minTokensOut | string | Minimum tokens expected |
| batchWindow | int | Batch window timestamp |
| blockNumber | int | Block when created |
| timestamp | date | Timestamp when created |
| resolved | boolean | Whether resolved |
| riskProfile | int | Risk profile ID (0-2) |

### BatchDepositEntity

Tracks aggregated batch deposits.

| Field | Type | Description |
|-------|------|-------------|
| id | string | {batchWindow}-{batchHash} |
| batchWindow | int | Batch window timestamp |
| totalAmount | string | Total deposited |
| depositCount | int | Number of deposits |
| blockNumber | int | Block when submitted |
| timestamp | date | Timestamp when submitted |
| resolved | boolean | Whether resolved |

### BatchWithdrawalEntity

Tracks aggregated batch withdrawals.

| Field | Type | Description |
|-------|------|-------------|
| id | string | {batchWindow}-{batchHash} |
| batchWindow | int | Batch window timestamp |
| totalShares | string | Total shares redeemed |
| withdrawalCount | int | Number of withdrawals |
| blockNumber | int | Block when submitted |
| timestamp | date | Timestamp when submitted |
| resolved | boolean | Whether resolved |

### AccountNFTStateEntity

Tracks current state of user accounts.

| Field | Type | Description |
|-------|------|-------------|
| id | string | {user}-{riskProfile} |
| user | string | User address (lowercase) |
| riskProfile | int | Risk profile ID |
| balance | string | Current share balance |
| pendingDeposit | string | Pending deposit amount |
| pendingWithdrawal | string | Pending withdrawal shares |
| blockNumber | int | Last update block |
| timestamp | date | Last update timestamp |

## Event Processing Flow

### 1. DepositRequested

```typescript
Event → Store DepositRequestEntity
      → Increment deposit_requested counter
      → Update metrics
```

**Trigger**: User calls `requestDeposit()` on BellveProvisioner

**Data stored**:
- User address
- Token and amount
- Batch window assignment
- Risk profile
- resolved = false

### 2. WithdrawalRequested

```typescript
Event → Store WithdrawalRequestEntity
      → Increment withdrawal_requested counter
      → Update metrics
```

**Trigger**: User calls `requestWithdrawal()` on BellveProvisioner

**Data stored**:
- User address
- Shares and minimum tokens
- Batch window assignment
- Risk profile
- resolved = false

### 3. BatchDepositSubmitted

```typescript
Event → Store BatchDepositEntity
      → Increment batch_deposit_submitted counter
```

**Trigger**: Operator calls `submitBatchDeposits()`

**Data stored**:
- Batch window
- Total amount and deposit count
- resolved = false

### 4. BatchWithdrawalSubmitted

```typescript
Event → Store BatchWithdrawalEntity
      → Increment batch_withdrawal_submitted counter
```

**Trigger**: Operator calls `submitBatchWithdrawals()`

**Data stored**:
- Batch window
- Total shares and withdrawal count
- resolved = false

### 5. DepositResolved

```typescript
Event → Update DepositRequestEntity.resolved = true
      → Increment deposit_resolved counter
      → Update AccountNFTStateEntity (if tracked)
```

**Trigger**: Operator calls `resolveBatchDeposits()`

**Updates**:
- Mark deposit as resolved
- Track share distribution

### 6. WithdrawalResolved

```typescript
Event → Update WithdrawalRequestEntity.resolved = true
      → Increment withdrawal_resolved counter
      → Update AccountNFTStateEntity (if tracked)
```

**Trigger**: Operator calls `resolveBatchWithdrawals()`

**Updates**:
- Mark withdrawal as resolved
- Track token distribution

## Metrics & Counters

The indexer tracks the following metrics:

- `deposit_requested_counter`: Total deposit requests
- `deposit_resolved_counter`: Total deposits resolved
- `withdrawal_requested_counter`: Total withdrawal requests
- `withdrawal_resolved_counter`: Total withdrawals resolved
- `batch_deposit_submitted_counter`: Total batch deposits submitted
- `batch_withdrawal_submitted_counter`: Total batch withdrawals submitted

All counters include labels for:
- `user`: User address
- `riskProfile`: Risk profile ID (where applicable)

## Setup & Configuration

### 1. Install Dependencies

```bash
cd indexer
pnpm install
```

### 2. Configure Constants

Edit `src/constant.ts` with deployed contract addresses:

```typescript
export const BELLVE_PROVISIONER_ADDRESS = "0x...";  // From deployment
export const START_BLOCK = 123456;  // Deployment block
```

### 3. Copy ABIs

ABIs must be present in `abis/` directory:

```bash
cd ../scripts
pnpm generate-abis
```

### 4. Generate Types

Sentio generates TypeScript types from ABIs:

```bash
cd ../indexer
pnpm gen
```

This creates processor types in `.sentio/` directory.

### 5. Update Processor

After `pnpm gen`, uncomment the event handlers in `src/processor.ts`.

The generated types will look like:

```typescript
import {
  BellveProvisionerProcessor,
  DepositRequestedEvent,
  // ... other events
} from './types/eth/bellveprovisioner.js';
```

### 6. Build

```bash
pnpm build
```

### 7. Test Locally

```bash
pnpm test
```

### 8. Upload to Sentio Cloud

```bash
# Set API key
export SENTIO_API_KEY=...

# Upload
pnpm upload
```

## Querying Data

### Via Sentio Dashboard

After uploading, access your dashboard at:
```
https://app.sentio.xyz/<your-project>
```

### Via GraphQL API

Sentio provides a GraphQL API:

```graphql
query {
  depositRequestEntities(
    where: { resolved: false }
    orderBy: timestamp_DESC
  ) {
    id
    user
    amount
    batchWindow
    timestamp
  }
}
```

### Via SQL (Advanced)

Sentio allows direct SQL queries:

```sql
SELECT 
  batch_window,
  COUNT(*) as deposit_count,
  SUM(CAST(amount AS NUMERIC)) as total_amount
FROM deposit_request_entity
WHERE resolved = false
GROUP BY batch_window
ORDER BY batch_window DESC;
```

## Reorg Handling

Sentio automatically handles blockchain reorganizations:

1. Events from reorged blocks are removed from storage
2. Affected blocks are reprocessed
3. Counters are adjusted accordingly

No manual intervention required.

## Performance Optimization

### Indexing Strategy

- **Start Block**: Set to deployment block to avoid unnecessary scanning
- **Batch Processing**: Sentio processes events in batches for efficiency
- **Selective Indexing**: Only index events from BellveProvisioner contract

### Entity Design

- **Composite IDs**: Use meaningful IDs (`{batchWindow}-{batchHash}`)
- **Denormalization**: Store aggregated data to avoid joins
- **Minimal Fields**: Only store essential data

## Monitoring

### Health Checks

Monitor indexer health via Sentio dashboard:

- Latest indexed block
- Sync lag (seconds behind chain head)
- Event processing rate
- Error rate

### Alerts

Set up alerts for:
- Sync lag > 5 minutes
- Error rate > 1%
- No events processed for > 1 hour

## Troubleshooting

### Issue: "Failed to generate types"

**Solution**:
```bash
# Ensure ABIs are present
ls abis/

# Copy ABIs if missing
cd ../scripts && pnpm generate-abis

# Try gen again
cd ../indexer && pnpm gen
```

### Issue: "Contract address not found"

**Solution**: Update `src/constant.ts` with correct deployed address.

### Issue: "Upload failed"

**Solution**:
```bash
# Check API key
echo $SENTIO_API_KEY

# Try logging in
sentio login

# Upload again
pnpm upload
```

### Issue: "No events being indexed"

**Possible causes**:
- Wrong contract address in `constant.ts`
- Wrong chain ID in `sentio.yaml`
- Start block is after deployment
- No transactions have occurred yet

## Development Workflow

1. Make changes to `processor.ts`
2. Test locally: `pnpm test`
3. Build: `pnpm build`
4. Upload: `pnpm upload`
5. Verify in Sentio dashboard

## Best Practices

1. **Version Control**: Commit entity changes carefully (schema migrations are complex)
2. **Testing**: Test event handlers with mock data before uploading
3. **Monitoring**: Set up alerts for production indexer
4. **Documentation**: Document any custom metrics or counters
5. **Optimization**: Avoid heavy computations in event handlers

## Resources

- [Sentio Documentation](https://docs.sentio.xyz)
- [Sentio SDK Reference](https://docs.sentio.xyz/reference/sdk)
- [GraphQL API Guide](https://docs.sentio.xyz/guides/querying-data)
- [Entity Schema Guide](https://docs.sentio.xyz/guides/entities)

---

**Remember**: TESTNET ONLY - Base Sepolia - For evaluation purposes - No warranties

