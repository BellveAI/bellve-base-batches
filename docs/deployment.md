# Deployment Guide - Bellve Buildathon

## ⚠️ TESTNET DEPLOYMENT ONLY ⚠️

**CRITICAL WARNINGS:**
- This deployment guide is for **Base Sepolia testnet ONLY**
- **DO NOT deploy to mainnet** - this is a prototype system
- This system is provided for evaluation purposes with no warranties
- No incentives, rewards, or expectations of profit
- Implementation subject to change without notice

---

## Prerequisites

Before deploying, ensure you have:

1. **Foundry** installed ([getfoundry.sh](https://getfoundry.sh))
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **pnpm** installed (v8.0+)
   ```bash
   npm install -g pnpm
   ```

3. **Base Sepolia Testnet ETH**
   - Get from [Coinbase Faucet](https://www.coinbase.com/faucets/base-ethereum-sepolia-faucet)
   - You'll need ~0.1 ETH for deployment + gas

4. **RPC URL** for Base Sepolia
   - Public: `https://sepolia.base.org`
   - Or get dedicated RPC from [Alchemy](https://www.alchemy.com/) or [Infura](https://www.infura.io/)

5. **Etherscan API Key** (for verification)
   - Get from [Basescan](https://basescan.org/apis)

---

## Step 1: Configure Environment

```bash
# Navigate to project root
cd bellve-buildathon

# Copy environment template
cp .env.example .env

# Edit .env with your values
nano .env
```

Required variables:
```bash
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
DEPLOYER_PRIVATE_KEY=0x...  # Your wallet private key (testnet only!)
ETHERSCAN_API_KEY=...       # For contract verification
```

**⚠️ SECURITY**: Never commit your `.env` file. Use a dedicated testnet wallet.

---

## Step 2: Install Dependencies

```bash
# Install workspace dependencies
pnpm install

# Install Foundry dependencies
cd contracts
forge install
cd ..
```

---

## Step 3: Build Contracts

```bash
cd contracts
make build
```

Expected output:
```
🔨 Building contracts...
[⠊] Compiling...
[⠒] Compiling 15 files with 0.8.29
[⠢] Solc 0.8.29 finished in 2.50s
Compiler run successful!
```

---

## Step 4: Run Tests

```bash
make test
```

All tests should pass. If any fail, do NOT proceed with deployment.

---

## Step 5: Deploy to Base Sepolia

```bash
make deploy
```

This will:
1. Deploy all contracts (Registry, NFT, Vault, Provisioner, Mocks)
2. Wire dependencies and set permissions
3. Verify contracts on Basescan
4. Print deployment summary

**Deployment takes ~5-10 minutes** including verification.

Expected output:
```
======================================================================
  BELLVE BUILDATHON DEPLOYMENT - BASE SEPOLIA TESTNET ONLY
======================================================================

WARNING: This is a PROTOTYPE for evaluation purposes only
  - NOT production ready
  - Subject to change without notice
  - No incentives or guarantees
  - TESTNET deployment ONLY

...

Core Contracts:
  AddressRegistry:        0x...
  BellveAccountNFT:       0x...
  BellveVault:            0x...
  BellveProvisioner:      0x...

Mock Contracts:
  MockUSDC:               0x...
  MockGtUSDa:             0x...
  MockPriceCalculator:    0x...
```

**📝 SAVE THESE ADDRESSES** - you'll need them for the indexer and demo!

---

## Step 6: Update Indexer Configuration

```bash
cd ../indexer

# Update src/constant.ts with deployed addresses
nano src/constant.ts
```

Update these values:
```typescript
export const BELLVE_PROVISIONER_ADDRESS = "0x...";  // From deployment
export const START_BLOCK = 123456;  // Deployment block number
```

---

## Step 7: Copy ABIs to Indexer

```bash
# From project root
cd scripts
pnpm generate-abis  # This copies ABIs to indexer/abis/
```

Or manually:
```bash
cp ../contracts/out/BellveProvisioner.sol/BellveProvisioner.json ../indexer/abis/
cp ../contracts/out/BellveAccountNFT.sol/BellveAccountNFT.json ../indexer/abis/
```

---

## Step 8: Build Indexer

```bash
cd ../indexer

# Generate Sentio types from ABIs
pnpm gen

# Build indexer
pnpm build
```

---

## Step 9: Update Demo Configuration

```bash
cd ../demo

# Update .env with contract addresses
./sync-addresses.sh  # Auto-sync from deployment

# Or manually edit demo/.env
nano .env
```

---

## Step 10: Test End-to-End

```bash
# Start demo webapp
cd demo
pnpm dev
```

Open http://localhost:5173 and:
1. Connect MetaMask to Base Sepolia
2. Test deposit flow
3. Test batch processing (requires operator role)
4. Test withdrawal flow

---

## Verification

### Verify Contracts on Basescan

If auto-verification failed during deployment:

```bash
cd contracts

# Verify each contract
forge verify-contract \
  --rpc-url base_sepolia \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  <CONTRACT_ADDRESS> \
  src/<ContractFile>.sol:<ContractName>
```

Example:
```bash
forge verify-contract \
  --rpc-url base_sepolia \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  0x123... \
  src/BellveProvisioner.sol:BellveProvisioner
```

---

## Deploy Indexer to Sentio Cloud

```bash
cd indexer

# Ensure you have Sentio API key in .env
export SENTIO_API_KEY=...

# Upload to Sentio
pnpm upload
```

Your indexer will now process events and make data available via Sentio dashboard.

---

## Troubleshooting

### Issue: "Insufficient funds for gas"
- **Solution**: Get more testnet ETH from faucet

### Issue: "Nonce too low"
- **Solution**: Reset MetaMask account or increase nonce

### Issue: "Contract verification failed"
- **Solution**: Run manual verification (see Verification section)

### Issue: "RPC rate limit exceeded"
- **Solution**: Use dedicated RPC from Alchemy/Infura

### Issue: "ABIs not found in indexer"
- **Solution**: Run `make build` in contracts, then copy ABIs

---

## Post-Deployment Checklist

- [ ] All contracts deployed successfully
- [ ] Contracts verified on Basescan
- [ ] Deployment addresses saved
- [ ] Indexer configuration updated
- [ ] Demo webapp configuration updated
- [ ] End-to-end test completed
- [ ] Indexer uploaded to Sentio
- [ ] Documentation updated with addresses

---

## Security Notes

🔒 **For Production Deployment** (NOT for this buildathon):
- Use multi-sig wallet for admin
- Implement timelock on sensitive functions
- Complete security audit
- Set up monitoring and alerting
- Implement rate limiting
- Add circuit breakers
- Test on testnet for extended period

---

## Support

For deployment issues:
- Email: buildathon@bellve.io
- Check deployment logs carefully
- Review contract events on Basescan

---

**Remember: TESTNET ONLY - For evaluation purposes - No warranties or incentives**

