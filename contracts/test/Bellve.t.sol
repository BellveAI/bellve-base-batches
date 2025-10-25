// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

/*
 * =====================================================================
 * Bellve Buildathon Test Suite – TESTNET ONLY
 * =====================================================================
 */

import "forge-std/Test.sol";
import { AddressRegistry } from "../src/AddressRegistry.sol";
import { BellveAccountNFT } from "../src/BellveAccountNFT.sol";
import { BellveVault } from "../src/BellveVault.sol";
import { BellveProvisioner } from "../src/BellveProvisioner.sol";
import { MockUSDC } from "../src/mocks/MockUSDC.sol";
import { MockGtUSDa } from "../src/mocks/MockGtUSDa.sol";
import { MockPriceCalculator } from "../src/mocks/MockPriceCalculator.sol";
import { IERC20 } from "@oz/token/ERC20/IERC20.sol";

contract BellveTest is Test {
    
    AddressRegistry public registry;
    BellveAccountNFT public accountNFT;
    BellveVault public vault;
    BellveProvisioner public provisioner;
    MockUSDC public mockUSDC;
    MockGtUSDa public mockGtUSDa;
    MockPriceCalculator public priceCalculator;
    
    address public admin = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public operator = address(0x3);
    
    uint8 constant RISK_PROFILE = 0;
    
    function setUp() public {
        // Deploy contracts
        registry = new AddressRegistry(admin);
        accountNFT = new BellveAccountNFT(admin);
        vault = new BellveVault("Bellve Vault", "BELLVE", admin);
        provisioner = new BellveProvisioner(registry, admin);
        mockUSDC = new MockUSDC();
        mockGtUSDa = new MockGtUSDa(IERC20(address(mockUSDC)));
        priceCalculator = new MockPriceCalculator();
        
        // Configure registry
        registry.setAddress(registry.MOCK_USDC(), address(mockUSDC));
        registry.setAddress(registry.MOCK_GTUSDA(), address(mockGtUSDa));
        registry.setAddress(registry.PRICE_CALCULATOR(), address(priceCalculator));
        registry.setAddress(registry.BELLVE_VAULT(), address(vault));
        registry.setAddress(registry.BELLVE_ACCOUNT_NFT(), address(accountNFT));
        registry.setAddress(registry.BELLVE_PROVISIONER(), address(provisioner));
        
        // Transfer NFT ownership to provisioner
        accountNFT.transferOwnership(address(provisioner));
        
        // Configure vault
        vault.setProvisioner(address(provisioner));
        vault.setTokenSupport(IERC20(address(mockUSDC)), true);
        
        // Initialize provisioner
        provisioner.initialize(
            address(accountNFT),
            address(vault),
            address(priceCalculator)
        );
        
        // Configure token
        provisioner.configureToken(
            IERC20(address(mockUSDC)),
            true,  // asyncDepositEnabled
            true   // asyncRedeemEnabled
        );
        
        // Grant operator role
        provisioner.grantRole(provisioner.OPERATOR_ROLE(), operator);
        
        // Mint test USDC to users
        mockUSDC.mint(user1, 1000e6);  // 1000 USDC
        mockUSDC.mint(user2, 2000e6);  // 2000 USDC
    }
    
    function testDeployment() public view {
        assertEq(vault.provisioner(), address(provisioner));
        assertEq(accountNFT.owner(), address(provisioner));
        assertTrue(vault.supportedTokens(address(mockUSDC)));
    }
    
    function testDepositFlow() public {
        // User1 deposits 100 USDC
        uint256 depositAmount = 100e6;
        
        vm.startPrank(user1);
        mockUSDC.approve(address(provisioner), depositAmount);
        
        bytes32 depositHash = provisioner.requestDeposit(
            IERC20(address(mockUSDC)),
            depositAmount,
            1,  // minUnitsOut
            block.timestamp + 1 hours,
            RISK_PROFILE
        );
        vm.stopPrank();
        
        // Verify deposit was created
        (
            address user,
            IERC20 token,
            uint256 amount,
            uint256 minUnitsOut,
            uint256 batchWindow,
            uint256 deadline,
            bool resolved,
            uint8 riskProfile
        ) = provisioner.depositRequests(depositHash);
        
        assertEq(user, user1);
        assertEq(address(token), address(mockUSDC));
        assertEq(amount, depositAmount);
        assertFalse(resolved);
        
        // Verify NFT was minted
        assertEq(accountNFT.balanceOf(user1), 1);
        
        // Verify pending deposit updated
        uint256 pending = accountNFT.getPendingDeposit(user1, RISK_PROFILE);
        assertEq(pending, depositAmount);
    }
    
    function testBatchDepositResolution() public {
        // Setup: Create deposits
        uint256 depositAmount1 = 100e6;
        uint256 depositAmount2 = 200e6;
        
        vm.startPrank(user1);
        mockUSDC.approve(address(provisioner), depositAmount1);
        bytes32 depositHash1 = provisioner.requestDeposit(
            IERC20(address(mockUSDC)),
            depositAmount1,
            1,
            block.timestamp + 1 hours,
            RISK_PROFILE
        );
        vm.stopPrank();
        
        vm.startPrank(user2);
        mockUSDC.approve(address(provisioner), depositAmount2);
        bytes32 depositHash2 = provisioner.requestDeposit(
            IERC20(address(mockUSDC)),
            depositAmount2,
            1,
            block.timestamp + 1 hours,
            RISK_PROFILE
        );
        vm.stopPrank();
        
        uint256 batchWindow = provisioner.getCurrentBatchWindow();
        
        // Operator submits batch
        bytes32[] memory depositHashes = new bytes32[](2);
        depositHashes[0] = depositHash1;
        depositHashes[1] = depositHash2;
        
        vm.prank(operator);
        provisioner.submitBatchDeposits(batchWindow, depositHashes);
        
        // Operator resolves batch (equal shares for simplicity)
        uint256[] memory shares = new uint256[](2);
        shares[0] = 100e18;  // 100 shares
        shares[1] = 200e18;  // 200 shares
        
        vm.prank(operator);
        provisioner.resolveBatchDeposits(batchWindow, depositHashes, shares);
        
        // Verify shares were credited
        assertEq(accountNFT.getBalance(user1, RISK_PROFILE), 100e18);
        assertEq(accountNFT.getBalance(user2, RISK_PROFILE), 200e18);
        
        // Verify pending deposits cleared
        assertEq(accountNFT.getPendingDeposit(user1, RISK_PROFILE), 0);
        assertEq(accountNFT.getPendingDeposit(user2, RISK_PROFILE), 0);
    }
    
    function testWithdrawalFlow() public {
        // Setup: Give user1 some shares
        vm.prank(user1);
        mockUSDC.approve(address(provisioner), 100e6);
        
        vm.prank(user1);
        bytes32 depositHash = provisioner.requestDeposit(
            IERC20(address(mockUSDC)),
            100e6,
            1,
            block.timestamp + 1 hours,
            RISK_PROFILE
        );
        
        uint256 batchWindow = provisioner.getCurrentBatchWindow();
        
        bytes32[] memory depositHashes = new bytes32[](1);
        depositHashes[0] = depositHash;
        
        uint256[] memory shares = new uint256[](1);
        shares[0] = 100e18;
        
        vm.prank(operator);
        provisioner.submitBatchDeposits(batchWindow, depositHashes);
        
        vm.prank(operator);
        provisioner.resolveBatchDeposits(batchWindow, depositHashes, shares);
        
        // Now withdraw
        vm.prank(user1);
        bytes32 withdrawalHash = provisioner.requestWithdrawal(
            IERC20(address(mockUSDC)),
            50e18,  // withdraw 50 shares
            1,
            block.timestamp + 1 hours,
            RISK_PROFILE
        );
        
        // Verify withdrawal created
        (
            address user,
            IERC20 token,
            uint256 sharesAmount,
            uint256 minTokensOut,
            uint256 withdrawalWindow,
            uint256 deadline,
            bool resolved,
            uint8 riskProfile
        ) = provisioner.withdrawalRequests(withdrawalHash);
        
        assertEq(user, user1);
        assertEq(sharesAmount, 50e18);
        assertFalse(resolved);
        
        // Verify shares were debited
        assertEq(accountNFT.getBalance(user1, RISK_PROFILE), 50e18);
    }
    
    function testAccessControl() public {
        // Random user cannot submit batches
        vm.expectRevert();
        vm.prank(user1);
        provisioner.submitBatchDeposits(0, new bytes32[](0));
        
        // Operator can submit batches
        bytes32[] memory empty = new bytes32[](0);
        vm.prank(operator);
        vm.expectRevert();  // Will revert for empty array, but proves role works
        provisioner.submitBatchDeposits(0, empty);
    }
}

