/**
 * Bellve Buildathon Demo Configuration
 * TESTNET ONLY - Base Sepolia
 */

export const config = {
  // Contract addresses (from .env)
  BELLVE_PROVISIONER_ADDRESS: import.meta.env.VITE_BELLVE_PROVISIONER_ADDRESS || '',
  BELLVE_VAULT_ADDRESS: import.meta.env.VITE_BELLVE_VAULT_ADDRESS || '',
  BELLVE_ACCOUNT_NFT_ADDRESS: import.meta.env.VITE_BELLVE_ACCOUNT_NFT_ADDRESS || '',
  MOCK_GTUSD_ADDRESS: import.meta.env.VITE_MOCK_GTUSD_ADDRESS || '',
  MOCK_USDC_ADDRESS: import.meta.env.VITE_MOCK_USDC_ADDRESS || '',
  MOCK_PRICE_CALCULATOR_ADDRESS: import.meta.env.VITE_MOCK_PRICE_CALCULATOR_ADDRESS || '',

  // Network configuration
  RPC_URL: import.meta.env.VITE_RPC_URL || 'https://sepolia.base.org',
  CHAIN_ID: parseInt(import.meta.env.VITE_CHAIN_ID || '84532', 10),
  CHAIN_NAME: 'Base Sepolia',
  BLOCK_EXPLORER: 'https://sepolia.basescan.org',

  // App configuration
  BATCH_WINDOW_SIZE: 3600, // 1 hour in seconds
};

// Validate configuration
export function validateConfig() {
  const required = [
    'BELLVE_PROVISIONER_ADDRESS',
    'BELLVE_ACCOUNT_NFT_ADDRESS',
    'MOCK_USDC_ADDRESS',
  ];

  const missing = required.filter((key) => !config[key as keyof typeof config]);

  if (missing.length > 0) {
    console.warn('⚠️  Missing configuration:', missing);
    console.warn('Please update demo/.env with deployed contract addresses');
  }

  return missing.length === 0;
}

