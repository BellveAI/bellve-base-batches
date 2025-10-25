// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

/*
 * =====================================================================
 * Bellve Buildathon Deployment Script – TESTNET ONLY
 * =====================================================================
 * 
 * ⚠️  CRITICAL WARNING: BASE SEPOLIA TESTNET DEPLOYMENT ONLY
 * 
 * This script deploys the Bellve MVP system for evaluation purposes only.
 * DO NOT deploy to mainnet. This is a prototype for the Base Batches Buildathon.
 * 
 * =====================================================================
 */

import "forge-std/Script.sol";
import "forge-std/console.sol";

import { AddressRegistry } from "../src/AddressRegistry.sol";
import { BellveAccountNFT } from "../src/BellveAccountNFT.sol";
import { BellveVault } from "../src/BellveVault.sol";
import { BellveProvisioner } from "../src/BellveProvisioner.sol";
import { MockUSDC } from "../src/mocks/MockUSDC.sol";
import { MockGtUSDa } from "../src/mocks/MockGtUSDa.sol";
import { MockPriceCalculator } from "../src/mocks/MockPriceCalculator.sol";
import { IERC20 } from "@oz/token/ERC20/IERC20.sol";

contract DeployBellve is Script {
    
    function run() external {
        console.log("======================================================================");
        console.log("  BELLVE BUILDATHON DEPLOYMENT - BASE SEPOLIA TESTNET ONLY");
        console.log("======================================================================");
        console.log("");
        console.log("WARNING: This is a PROTOTYPE for evaluation purposes only");
        console.log("  - NOT production ready");
        console.log("  - Subject to change without notice");
        console.log("  - No incentives or guarantees");
        console.log("  - TESTNET deployment ONLY");
        console.log("");
        console.log("======================================================================");
        console.log("");
        
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance);
        console.log("Chain ID:", block.chainid);
        console.log("Block number:", block.number);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy AddressRegistry
        console.log("1/7 Deploying AddressRegistry...");
        AddressRegistry registry = new AddressRegistry(deployer);
        console.log("  -> AddressRegistry:", address(registry));
        console.log("");
        
        // 2. Deploy BellveAccountNFT
        console.log("2/7 Deploying BellveAccountNFT...");
        BellveAccountNFT accountNFT = new BellveAccountNFT(deployer);
        console.log("  -> BellveAccountNFT:", address(accountNFT));
        console.log("");
        
        // 3. Deploy BellveVault
        console.log("3/7 Deploying BellveVault...");
        BellveVault vault = new BellveVault(
            "Bellve Vault",
            "BELLVE",
            deployer
        );
        console.log("  -> BellveVault:", address(vault));
        console.log("");
        
        // 4. Deploy BellveProvisioner
        console.log("4/7 Deploying BellveProvisioner...");
        BellveProvisioner provisioner = new BellveProvisioner(
            registry,
            deployer
        );
        console.log("  -> BellveProvisioner:", address(provisioner));
        console.log("");
        
        // 5. Deploy Mock Tokens
        console.log("5/7 Deploying Mock Tokens...");
        MockUSDC mockUSDC = new MockUSDC();
        console.log("  -> MockUSDC:", address(mockUSDC));
        
        MockGtUSDa mockGtUSDa = new MockGtUSDa(IERC20(address(mockUSDC)));
        console.log("  -> MockGtUSDa:", address(mockGtUSDa));
        console.log("");
        
        // 6. Deploy MockPriceCalculator
        console.log("6/7 Deploying MockPriceCalculator...");
        MockPriceCalculator priceCalculator = new MockPriceCalculator();
        console.log("  -> MockPriceCalculator:", address(priceCalculator));
        console.log("");
        
        // 7. Wire everything together
        console.log("7/7 Configuring system...");
        
        // Register addresses in registry
        console.log("  - Registering addresses in registry...");
        registry.setAddress(registry.MOCK_USDC(), address(mockUSDC));
        registry.setAddress(registry.MOCK_GTUSDA(), address(mockGtUSDa));
        registry.setAddress(registry.PRICE_CALCULATOR(), address(priceCalculator));
        registry.setAddress(registry.BELLVE_VAULT(), address(vault));
        registry.setAddress(registry.BELLVE_ACCOUNT_NFT(), address(accountNFT));
        registry.setAddress(registry.BELLVE_PROVISIONER(), address(provisioner));
        
        // Set provisioner as owner of NFT
        console.log("  - Transferring NFT ownership to provisioner...");
        accountNFT.transferOwnership(address(provisioner));
        
        // Set provisioner in vault
        console.log("  - Setting provisioner in vault...");
        vault.setProvisioner(address(provisioner));
        vault.setTokenSupport(IERC20(address(mockUSDC)), true);
        
        // Initialize provisioner
        console.log("  - Initializing provisioner...");
        provisioner.initialize(
            address(accountNFT),
            address(vault),
            address(priceCalculator)
        );
        
        // Configure USDC token
        console.log("  - Configuring USDC token...");
        provisioner.configureToken(
            IERC20(address(mockUSDC)),
            true,  // asyncDepositEnabled
            true   // asyncRedeemEnabled
        );
        
        console.log("  - Configuration complete!");
        console.log("");
        
        vm.stopBroadcast();
        
        // Print deployment summary
        console.log("======================================================================");
        console.log("  DEPLOYMENT SUMMARY");
        console.log("======================================================================");
        console.log("");
        console.log("Core Contracts:");
        console.log("  AddressRegistry:       ", address(registry));
        console.log("  BellveAccountNFT:      ", address(accountNFT));
        console.log("  BellveVault:           ", address(vault));
        console.log("  BellveProvisioner:     ", address(provisioner));
        console.log("");
        console.log("Mock Contracts:");
        console.log("  MockUSDC:              ", address(mockUSDC));
        console.log("  MockGtUSDa:            ", address(mockGtUSDa));
        console.log("  MockPriceCalculator:   ", address(priceCalculator));
        console.log("");
        console.log("Configuration:");
        console.log("  NFT Owner:             ", accountNFT.owner());
        console.log("  Vault Owner:           ", vault.owner());
        console.log("  Vault Provisioner:     ", vault.provisioner());
        console.log("");
        console.log("======================================================================");
        console.log("");
        console.log("REMINDER: This deployment is for BASE SEPOLIA TESTNET ONLY");
        console.log("  - Save these addresses for the indexer and demo webapp");
        console.log("  - Run 'pnpm scripts:sync-addresses' to update .env files");
        console.log("");
        console.log("Next steps:");
        console.log("  1. Verify contracts on Basescan");
        console.log("  2. Update indexer configuration");
        console.log("  3. Update demo webapp configuration");
        console.log("  4. Test complete deposit/withdrawal flow");
        console.log("");
        console.log("======================================================================");
    }
}

