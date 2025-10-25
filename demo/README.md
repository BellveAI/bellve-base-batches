# Bellve Buildathon Demo Web Application

## ⚠️ TESTNET ONLY ⚠️

This demo webapp is for **Base Sepolia testnet ONLY**. Not production-ready. For evaluation purposes.

---

## Overview

A React-based web interface for interacting with the Bellve Buildathon smart contracts on Base Sepolia testnet.

## Features

### User Dashboard
- View AccountNFT state (balance, pending deposits/withdrawals)
- Mint test USDC
- Request deposits (USDC → Bellve shares)
- Request withdrawals (shares → USDC)
- Real-time balance updates

### Batch Processor (Operator Only)
- Submit deposit batches
- Resolve deposit batches (distribute shares)
- Submit withdrawal batches
- Resolve withdrawal batches (distribute tokens)
- Auto-extraction of hashes from transactions

### Mock gtUSDa Processor (Admin Only)
- View MockGtUSDa status
- Resolve deposit requests
- Resolve redeem requests
- Test hash validity

### Access Control Manager (Admin Only)
- View current roles
- Grant OPERATOR_ROLE
- Revoke roles
- Verify role assignments

## Prerequisites

- Node.js 18+ and pnpm
- MetaMask browser extension
- Base Sepolia testnet ETH
- Deployed Bellve contracts (see main README)

## Installation

```bash
# Install dependencies
pnpm install
```

## Configuration

### Quick Start: Sync Addresses

After deploying contracts:

```bash
./sync-addresses.sh
```

This automatically updates `.env` with the latest contract addresses.

### Manual Configuration

1. Copy `.env.example` to `.env`
2. Edit `.env` with your contract addresses:

```env
VITE_BELLVE_PROVISIONER_ADDRESS=0x...
VITE_BELLVE_VAULT_ADDRESS=0x...
VITE_BELLVE_ACCOUNT_NFT_ADDRESS=0x...
VITE_MOCK_GTUSD_ADDRESS=0x...
VITE_MOCK_USDC_ADDRESS=0x...
VITE_MOCK_PRICE_CALCULATOR_ADDRESS=0x...
VITE_RPC_URL=https://sepolia.base.org
VITE_CHAIN_ID=84532
```

## Running the App

```bash
# Development mode
pnpm dev
```

The app will open at `http://localhost:5173`

## MetaMask Setup

1. Add Base Sepolia network to MetaMask:
   - Network Name: Base Sepolia
   - RPC URL: https://sepolia.base.org
   - Chain ID: 84532
   - Currency Symbol: ETH
   - Block Explorer: https://sepolia.basescan.org

2. Import your test wallet private key

3. Connect to the app using "Connect MetaMask" button

## Usage Flows

### Complete Deposit Flow

1. **User Dashboard**:
   - Mint test USDC (e.g., 1000 USDC)
   - Approve USDC spending
   - Request deposit with desired amount
   - Note the depositHash from transaction

2. **Batch Processor** (Operator):
   - Enter deposit hashes (comma or newline separated)
   - Submit batch
   - Wait for confirmation

3. **Mock Processor** (Admin):
   - Paste depositRequestHash (auto-extracted)
   - Test hash to verify
   - Resolve deposit request

4. **Batch Processor** (Operator):
   - Enter shares to distribute per deposit
   - Resolve batch
   - Users receive shares

5. **User Dashboard**:
   - Refresh to see updated balance

### Complete Withdrawal Flow

1. **User Dashboard**:
   - Request withdrawal with share amount
   - Note the withdrawalHash

2. **Batch Processor** (Operator):
   - Enter withdrawal hashes
   - Submit batch withdrawals
   - Copy redeemRequestHash

3. **Mock Processor** (Admin):
   - Paste redeemRequestHash
   - Test and resolve redeem

4. **Batch Processor** (Operator):
   - Enter USDC distribution amounts
   - Resolve batch withdrawal

5. **User Dashboard**:
   - Refresh to see USDC received

## Key Features

### Auto-Hash Extraction
The webapp automatically extracts hashes from transaction receipts:
- `depositHash` from requestDeposit
- `withdrawalHash` from requestWithdrawal
- `depositRequestHash` from submitBatchDeposits
- `redeemRequestHash` from submitBatchWithdrawals

### Hash History
All hashes are stored in localStorage and persist across page reloads.

### Role-Based Access Control
UI dynamically shows/hides features based on user's roles:
- DEFAULT_ADMIN_ROLE: Full control
- OPERATOR_ROLE: Batch processing only

## Architecture

- **Frontend**: React + TypeScript + Vite
- **Web3**: web3.js v4
- **State Management**: React Context API
- **Styling**: CSS
- **Storage**: localStorage for hash history

## File Structure

```
demo/
├── src/
│   ├── abis/                    # Contract ABIs
│   ├── components/              # React components
│   │   ├── BellveMvp.tsx       # User dashboard
│   │   ├── BellveBatchProcessor.tsx  # Batch processing
│   │   ├── MockGtUsdaProcessor.tsx   # Mock gtUSDa controls
│   │   └── AccessControlManager.tsx  # Role management
│   ├── contexts/               # React contexts
│   │   ├── Web3Context.tsx     # Web3 connection
│   │   └── HashHistoryContext.tsx  # Hash storage
│   ├── hooks/                  # Custom hooks
│   │   └── useContracts.ts     # Contract instances
│   ├── utils/                  # Utility functions
│   │   ├── formatters.ts       # Amount formatting
│   │   └── admin.ts            # Admin checks
│   ├── styles/                 # CSS styles
│   │   └── app.css
│   ├── config.ts               # Configuration
│   ├── App.tsx                 # Main app
│   └── main.tsx                # Entry point
├── index.html
├── package.json
├── vite.config.ts
└── tsconfig.json
```

## Build for Production

```bash
pnpm build
```

The production build will be in the `dist/` directory.

## Troubleshooting

### MetaMask Connection Issues
- Ensure you're on Base Sepolia network
- Try disconnecting and reconnecting
- Clear MetaMask cache if needed

### Transaction Failures
- Check you have sufficient gas
- Ensure approvals are done before operations
- Verify you're using correct account for admin operations

### Hash Extraction Issues
- If auto-extraction fails, manually copy from transaction logs
- Check browser console for detailed error messages

## Implementation Notes

**Status**: Demo webapp structure created but components need implementation.

**To complete**:
1. Copy component implementations from `/Users/anthony/development/bellve/MVP-Vault-Contract/demo`
2. Adapt for new simplified contract interfaces
3. Update ABI imports
4. Test with deployed contracts

**Reference**: See existing demo at `MVP-Vault-Contract/demo` for component examples.

---

**Remember**: TESTNET ONLY - For evaluation purposes - No warranties or incentives

