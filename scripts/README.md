# Bellve Buildathon Scripts

Deployment and utility scripts for the Bellve Buildathon project.

## Scripts

### generate-abis.ts

Copies compiled contract ABIs to the indexer and demo packages.

**Usage:**
```bash
pnpm generate-abis
```

**Prerequisites:**
- Contracts must be built first: `cd contracts && make build`

**What it does:**
1. Reads compiled ABIs from `contracts/out/`
2. Copies to `indexer/abis/` for Sentio
3. Copies to `demo/src/abis/` for demo webapp
4. Reports success/failure for each contract

### deploy.ts

**Status**: To be implemented

Orchestrates the full deployment flow:
1. Validates environment variables
2. Runs Foundry deployment script
3. Parses deployment output
4. Saves addresses to `deployment/base-sepolia.json`
5. Updates demo `.env` with addresses

### verify.ts

**Status**: To be implemented

Automates contract verification on Basescan:
1. Reads deployed addresses
2. Runs `forge verify-contract` for each
3. Reports verification status

## Environment Variables

Required in `.env`:
- `BASE_SEPOLIA_RPC_URL` - RPC endpoint
- `DEPLOYER_PRIVATE_KEY` - Deployer wallet private key
- `ETHERSCAN_API_KEY` - For verification

## Workflow

1. **Build contracts**: `cd contracts && make build`
2. **Copy ABIs**: `pnpm generate-abis`
3. **Deploy**: `cd contracts && make deploy`
4. **Update configs**: Manually update indexer and demo with addresses
5. **Verify**: Check contracts on Basescan

## Manual Deployment

If automated scripts fail, deploy manually:

```bash
# 1. Deploy contracts
cd contracts
make deploy

# 2. Copy ABIs
cd ../scripts
pnpm generate-abis

# 3. Update indexer config
cd ../indexer
# Edit src/constant.ts with addresses
pnpm gen
pnpm build

# 4. Update demo config
cd ../demo
# Edit .env with addresses
pnpm install
pnpm dev
```

---

**Remember**: TESTNET ONLY - Base Sepolia deployment only

