# Bellve MVP Vault System - Base Batches Buildathon

---

## ⚠️ **CRITICAL TESTNET-ONLY DISCLAIMERS** ⚠️

**READ CAREFULLY BEFORE PROCEEDING:**

- **🔴 TESTNET DEPLOYMENT ONLY**: This system is designed exclusively for Base Sepolia testnet. Mainnet deployment is strictly prohibited.
- **🔴 PROTOTYPE STATUS**: This is NOT a final product. Implementation details are subject to change without notice.
- **🔴 NO INCENTIVES OR GUARANTEES**: There is no expectation of profit, token allocation, reward, or incentive from using this code.
- **🔴 FOR EVALUATION ONLY**: This repository is provided strictly for testing, experimentation, and hackathon review purposes.
- **🔴 NO WARRANTY**: Use at your own risk. See LICENSE for full legal terms.

---

## Overview

Bellve is a next-generation vault system that solves the fundamental challenge of asynchronous yield-bearing asset interactions in DeFi. Rather than forcing users to wait for slow external protocols to complete operations, Bellve implements a sophisticated batching mechanism that:

1. **Aggregates user requests** into time-windowed batches
2. **Processes batches asynchronously** with external yield protocols
3. **Distributes shares fairly** based on resolved exchange rates
4. **Tracks user state** via soulbound NFTs for transparent accounting

This architecture enables seamless integration with yield protocols like Aera while maintaining security, transparency, and capital efficiency.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER INTERACTIONS                         │
└────────────────┬────────────────────────────────┬────────────────┘
                 │                                │
                 ▼                                ▼
         ┌───────────────┐              ┌──────────────────┐
         │   Deposit     │              │   Withdrawal     │
         │   Request     │              │    Request       │
         └───────┬───────┘              └────────┬─────────┘
                 │                               │
                 └───────────┬───────────────────┘
                             ▼
                 ┌──────────────────────┐
                 │  BellveProvisioner   │
                 │  - Access Control    │
                 │  - Batch Windowing   │
                 │  - NFT Coordination  │
                 └──────────┬───────────┘
                            │
            ┌───────────────┼───────────────┐
            ▼               ▼               ▼
    ┌───────────────┐ ┌──────────┐ ┌────────────────┐
    │   Accounting  │ │  Vault   │ │ AccountNFT     │
    │   Module      │ │ Registry │ │ (Soulbound)    │
    └───────┬───────┘ └────┬─────┘ └────┬───────────┘
            │              │             │
            └──────────────┼─────────────┘
                           ▼
                   ┌──────────────┐
                   │ Mock gtUSDa  │
                   │ (Yield Asset)│
                   └──────┬───────┘
                          │
                          ▼
                   ┌──────────────┐
                   │    Sentio    │
                   │   Indexer    │
                   └──────┬───────┘
                          │
                          ▼
                   ┌──────────────┐
                   │  Demo WebApp │
                   │  (Automation)│
                   └──────────────┘
```

## Monorepo Structure

```
bellve-buildathon/
├── contracts/          # Foundry-based Solidity contracts
│   ├── src/           # Core contracts (Provisioner, Vault, NFT, Accounting)
│   ├── test/          # Foundry tests
│   ├── script/        # Deployment scripts
│   └── Makefile       # Build automation
├── indexer/           # Sentio-based event indexer
│   ├── src/           # Processor & entity definitions
│   └── abis/          # Contract ABIs
├── demo/              # React webapp for batch automation
│   ├── src/           # Components, contexts, hooks
│   └── abis/          # Contract ABIs
├── scripts/           # Deployment & utility scripts
├── docs/              # Architecture & deployment documentation
└── README.md          # This file
```

## Quick Start

### Prerequisites

- **Foundry** (forge, cast, anvil) - [Install here](https://book.getfoundry.sh/getting-started/installation)
- **pnpm** ≥ 8.0 - `npm install -g pnpm`
- **Node.js** ≥ 18.0
- **Base Sepolia testnet ETH** - [Get from faucet](https://www.coinbase.com/faucets/base-ethereum-sepolia-faucet)
- **MetaMask** browser extension

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd bellve-buildathon

# Install workspace dependencies
pnpm install

# Install Foundry dependencies
cd contracts
forge install
cd ..
```

### Configuration

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your values:
# - BASE_SEPOLIA_RPC_URL: Your RPC endpoint
# - DEPLOYER_PRIVATE_KEY: Your wallet private key (testnet only!)
# - ETHERSCAN_API_KEY: For contract verification
```

### Build & Test

```bash
# Build contracts
pnpm contracts:build

# Run Foundry tests
pnpm contracts:test

# Build indexer
pnpm indexer:gen
pnpm indexer:build

# Build demo webapp
pnpm demo:build
```

## Deployment Guide

### Step 1: Deploy Contracts to Base Sepolia

```bash
cd contracts
make deploy
# Or manually:
# forge script script/DeployBellve.s.sol:DeployBellve --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast --verify
```

This will deploy:
- AddressRegistry
- BellveAccountNFT
- BellveVault  
- BellveProvisioner
- MockGtUSDa
- MockUSDC
- MockPriceCalculator

Contract addresses will be logged to console and saved to `deployment/base-sepolia.json`.

### Step 2: Sync Addresses to Demo

```bash
cd demo
./sync-addresses.sh
```

This updates `.env` with deployed contract addresses.

### Step 3: Start Indexer

```bash
cd indexer

# Generate types and build
pnpm gen
pnpm build

# Upload to Sentio (optional)
pnpm upload
```

### Step 4: Run Demo Webapp

```bash
cd demo
pnpm dev
```

Open http://localhost:5173 and connect MetaMask to Base Sepolia.

## Usage Flows

### Complete Deposit Flow

1. **User Dashboard**: Mint test USDC, approve spending, request deposit
2. **Batch Processor** (Operator): Submit deposit batch to gtUSDa vault
3. **Mock Processor** (Admin): Resolve gtUSDa deposit request  
4. **Batch Processor**: Transfer custody & distribute shares to users
5. **User Dashboard**: View updated balance on AccountNFT

### Complete Withdrawal Flow

1. **User Dashboard**: Request withdrawal with share amount
2. **Batch Processor** (Operator): Submit withdrawal batch
3. **Mock Processor** (Admin): Resolve gtUSDa redeem request
4. **Batch Processor**: Distribute USDC to users
5. **User Dashboard**: View received USDC

See `docs/architecture.md` and `demo/README.md` for detailed workflows.

## Testing

### Foundry Tests

```bash
cd contracts
make test

# With gas reporting
forge test --gas-report

# With verbosity
forge test -vvv
```

Tests cover:
- End-to-end deposit & withdrawal flows
- Access control enforcement
- Accounting invariants
- Role-based permissions

### Indexer Tests

```bash
cd indexer
pnpm test
```

## Key Components

### Smart Contracts

- **BellveProvisioner**: Orchestrates deposits, withdrawals, and batch processing with AccessControl
- **BellveAccountNFT**: ERC721 soulbound token tracking user balances and lifecycle stats
- **BellveVault**: Vault coordinator for supported tokens
- **AddressRegistry**: Central registry for contract coordination
- **Vault001AccountingV1**: Accounting module for batch operations
- **Mocks**: MockGtUSDa (yield asset), MockUSDC (stablecoin), MockPriceCalculator

### Sentio Indexer

- **DepositRequestEntity**: Tracks individual deposit requests
- **WithdrawalRequestEntity**: Tracks individual withdrawal requests
- **BatchDepositEntity**: Aggregated batch deposit data
- **BatchWithdrawalEntity**: Aggregated batch withdrawal data
- **AccountNFTStateEntity**: Real-time NFT state snapshots

### Demo Webapp

- **BellveMvp**: User dashboard for deposits/withdrawals
- **BellveBatchProcessor**: Operator tool for batch management
- **MockGtUsdaProcessor**: Admin tool for mock vault operations
- **AccessControlManager**: Role management interface

## Documentation

- [Architecture Deep Dive](./docs/architecture.md) - System design and component interactions
- [Deployment Guide](./docs/deployment.md) - Detailed deployment instructions
- [Test Plan](./docs/test-plan.md) - Testing strategy and coverage
- [Indexer Documentation](./docs/indexer.md) - Sentio indexer setup and entity model
- [Demo Webapp Guide](./demo/README.md) - UI workflows and automation

## Security Considerations

🔐 This is a **prototype system for testnet evaluation**. The following security measures should be implemented before any production use:

- Multi-sig governance for admin operations
- Time-locks on sensitive functions
- Formal security audit by reputable firm
- Economic attack modeling
- Rate limiting and circuit breakers
- Insurance fund for edge cases

## Usage & Risks

⚠️ **REITERATION OF CRITICAL WARNINGS**:

This software is provided **AS-IS** for **TESTNET EVALUATION ONLY**. By using this software, you acknowledge:

1. This is NOT production-ready code
2. No warranties or guarantees are provided
3. Implementation details may change without notice
4. There are NO incentives, rewards, or expectations of profit
5. Deployment on mainnet is prohibited without explicit authorization
6. You use this software entirely at your own risk

See [LICENSE](./LICENSE) for complete legal terms.

## Contributing

This repository is **not accepting external contributions** at this time. It is provided for evaluation purposes only as part of the Base Batches Buildathon.

## License

**Copyright © 2025 Bellve. All rights reserved.**

This is proprietary software distributed under a restrictive license. See [LICENSE](./LICENSE) for full terms.

Redistribution requires prior written consent from Bellve.

## Contact

For questions about this buildathon submission:
- **Email**: jl@bellve.io
- **Twitter**: @bellve_ai

For licensing inquiries:
- **Email**: legal@bellve.io

---

**Built with ❤️ for Base Batches Buildathon**

*Testnet deployment only • No incentives • Subject to change • Use at your own risk*

