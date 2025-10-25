/**
 * Bellve Buildathon Demo App
 * 
 * ⚠️  TESTNET ONLY - Base Sepolia
 * 
 * This is a placeholder structure. Complete implementation should be based on
 * the reference demo at: /Users/anthony/development/bellve/MVP-Vault-Contract/demo
 */

import React from 'react';
import { config, validateConfig } from './config';

function App() {
  const [configValid, setConfigValid] = React.useState(false);

  React.useEffect(() => {
    setConfigValid(validateConfig());
  }, []);

  if (!configValid) {
    return (
      <div style={{ padding: '2rem', maxWidth: '800px', margin: '0 auto' }}>
        <h1>⚠️  Configuration Required</h1>
        <p>
          Please update <code>demo/.env</code> with deployed contract addresses.
        </p>
        <pre style={{ background: '#f5f5f5', padding: '1rem', borderRadius: '4px' }}>
          {`VITE_BELLVE_PROVISIONER_ADDRESS=0x...
VITE_BELLVE_VAULT_ADDRESS=0x...
VITE_BELLVE_ACCOUNT_NFT_ADDRESS=0x...
VITE_MOCK_GTUSD_ADDRESS=0x...
VITE_MOCK_USDC_ADDRESS=0x...
VITE_MOCK_PRICE_CALCULATOR_ADDRESS=0x...`}
        </pre>
        <p>
          After deploying contracts, run: <code>./sync-addresses.sh</code>
        </p>
      </div>
    );
  }

  return (
    <div style={{ padding: '2rem' }}>
      <header style={{ marginBottom: '2rem', borderBottom: '2px solid #333', paddingBottom: '1rem' }}>
        <h1>Bellve Buildathon Demo</h1>
        <p style={{ color: '#e74c3c', fontWeight: 'bold' }}>
          ⚠️  TESTNET ONLY - Base Sepolia - For Evaluation Purposes
        </p>
      </header>

      <main>
        <div style={{ marginBottom: '2rem', background: '#fff3cd', padding: '1rem', borderRadius: '4px' }}>
          <h2>🚧 Demo Implementation Needed</h2>
          <p>
            The demo webapp structure is in place but components need implementation.
          </p>
          <p>
            <strong>To complete:</strong>
          </p>
          <ol>
            <li>
              Copy component implementations from:{' '}
              <code>/Users/anthony/development/bellve/MVP-Vault-Contract/demo</code>
            </li>
            <li>Adapt for simplified contract interfaces</li>
            <li>Update ABI imports from <code>abis/</code> directory</li>
            <li>Test with deployed contracts</li>
          </ol>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '1rem' }}>
          <div style={{ border: '1px solid #ddd', padding: '1rem', borderRadius: '4px' }}>
            <h3>📊 User Dashboard</h3>
            <p>Mint USDC, request deposits/withdrawals, view balance</p>
            <p>
              <em>Component: BellveMvp.tsx</em>
            </p>
          </div>

          <div style={{ border: '1px solid #ddd', padding: '1rem', borderRadius: '4px' }}>
            <h3>⚙️  Batch Processor</h3>
            <p>Submit and resolve deposit/withdrawal batches</p>
            <p>
              <em>Component: BellveBatchProcessor.tsx</em>
            </p>
          </div>

          <div style={{ border: '1px solid #ddd', padding: '1rem', borderRadius: '4px' }}>
            <h3>🔧 Mock Processor</h3>
            <p>Resolve MockGtUSDa deposit/redeem requests</p>
            <p>
              <em>Component: MockGtUsdaProcessor.tsx</em>
            </p>
          </div>

          <div style={{ border: '1px solid #ddd', padding: '1rem', borderRadius: '4px' }}>
            <h3>🔐 Access Control</h3>
            <p>Manage roles (grant/revoke OPERATOR_ROLE)</p>
            <p>
              <em>Component: AccessControlManager.tsx</em>
            </p>
          </div>
        </div>

        <div style={{ marginTop: '2rem', background: '#d1ecf1', padding: '1rem', borderRadius: '4px' }}>
          <h3>📍 Current Configuration</h3>
          <pre style={{ background: '#fff', padding: '1rem', borderRadius: '4px', overflow: 'auto' }}>
            {JSON.stringify(config, null, 2)}
          </pre>
        </div>
      </main>
    </div>
  );
}

export default App;

