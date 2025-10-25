#!/usr/bin/env tsx

/**
 * Generate ABIs Script
 * Copies compiled contract ABIs to indexer and demo packages
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const ROOT_DIR = path.resolve(__dirname, '..');
const CONTRACTS_OUT_DIR = path.join(ROOT_DIR, 'contracts', 'out');
const INDEXER_ABIS_DIR = path.join(ROOT_DIR, 'indexer', 'abis');
const DEMO_ABIS_DIR = path.join(ROOT_DIR, 'demo', 'src', 'abis');

const CONTRACTS = [
  'BellveProvisioner',
  'BellveAccountNFT',
  'BellveVault',
  'AddressRegistry',
  'MockUSDC',
  'MockGtUSDa',
  'MockPriceCalculator',
];

console.log('🔧 Generating ABIs for indexer and demo...\n');

// Ensure target directories exist
if (!fs.existsSync(INDEXER_ABIS_DIR)) {
  fs.mkdirSync(INDEXER_ABIS_DIR, { recursive: true });
}
if (!fs.existsSync(DEMO_ABIS_DIR)) {
  fs.mkdirSync(DEMO_ABIS_DIR, { recursive: true });
}

let successCount = 0;
let errorCount = 0;

for (const contractName of CONTRACTS) {
  try {
    const sourcePath = path.join(
      CONTRACTS_OUT_DIR,
      `${contractName}.sol`,
      `${contractName}.json`
    );

    if (!fs.existsSync(sourcePath)) {
      console.error(`❌ ABI not found: ${contractName}`);
      errorCount++;
      continue;
    }

    const abiData = JSON.parse(fs.readFileSync(sourcePath, 'utf8'));

    // Copy to indexer
    fs.writeFileSync(
      path.join(INDEXER_ABIS_DIR, `${contractName}.json`),
      JSON.stringify(abiData, null, 2)
    );

    // Copy to demo
    fs.writeFileSync(
      path.join(DEMO_ABIS_DIR, `${contractName}.json`),
      JSON.stringify(abiData, null, 2)
    );

    console.log(`✅ ${contractName}`);
    successCount++;
  } catch (error) {
    console.error(`❌ Error processing ${contractName}:`, error);
    errorCount++;
  }
}

console.log('');
console.log('═══════════════════════════════════════');
console.log(`Summary: ${successCount} successful, ${errorCount} failed`);
console.log('═══════════════════════════════════════');

if (errorCount > 0) {
  console.error('\n⚠️  Some ABIs failed to copy. Check errors above.');
  process.exit(1);
}

console.log('\n✅ All ABIs copied successfully!');
console.log('\nNext steps:');
console.log('  1. cd indexer && pnpm gen');
console.log('  2. cd demo && pnpm install');

