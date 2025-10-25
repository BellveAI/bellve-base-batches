/* tslint:disable */
/* eslint-disable */

// =====================================================================
// Bellve Buildathon Indexer Configuration
// =====================================================================
// 
// ⚠️ TESTNET ONLY - Base Sepolia (Chain ID: 84532)
// 
// These addresses should be updated after deployment.
// Run the deployment script and update these values.
// 
// =====================================================================

export const BASE_SEPOLIA_CHAIN_ID = 84532;

// Contract Addresses (UPDATE AFTER DEPLOYMENT)
export const BELLVE_PROVISIONER_ADDRESS = process.env.BELLVE_PROVISIONER_ADDRESS || "";
export const BELLVE_VAULT_ADDRESS = process.env.BELLVE_VAULT_ADDRESS || "";
export const BELLVE_ACCOUNT_NFT_ADDRESS = process.env.BELLVE_ACCOUNT_NFT_ADDRESS || "";
export const MOCK_GTUSDA_ADDRESS = process.env.MOCK_GTUSDA_ADDRESS || "";
export const MOCK_USDC_ADDRESS = process.env.MOCK_USDC_ADDRESS || "";

// Start block for indexing (UPDATE AFTER DEPLOYMENT)
export const START_BLOCK = parseInt(process.env.START_BLOCK || "0", 10);

// Indexing configuration
export const BATCH_WINDOW_SIZE = 3600; // 1 hour in seconds

