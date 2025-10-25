// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

/*
 * =====================================================================
 * Bellve Buildathon Prototype – TESTNET ONLY
 * =====================================================================
 * 
 * ⚠️  WARNING: This code is provided for EVALUATION PURPOSES ONLY
 * 
 * - Deployment is intended for Base Sepolia testnet ONLY
 * - This is NOT the final product
 * - Implementation details are subject to change without notice
 * - There is NO incentive, warranty, or expectation of profit
 * - Code is provided strictly for testing, experimentation, and hackathon review
 * 
 * =====================================================================
 */

import { IERC20 } from "@oz/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@oz/token/ERC20/utils/SafeERC20.sol";
import { AccessControl } from "@oz/access/AccessControl.sol";
import { ReentrancyGuard } from "@oz/utils/ReentrancyGuard.sol";

import { AddressRegistry } from "./AddressRegistry.sol";
import { RegistryConsumer } from "./RegistryConsumer.sol";
import { IPriceAndFeeCalculator } from "./interfaces/IPriceAndFeeCalculator.sol";
import { IBellveAccountNFT } from "./interfaces/IBellveAccountNFT.sol";
import { BellveVault } from "./BellveVault.sol";
import { TokenDetails, DepositRequest, WithdrawalRequest, BatchDeposit, BatchWithdrawal } from "./Types.sol";

/// @title BellveProvisioner
/// @notice Orchestrates deposits, withdrawals, and batch processing for Bellve
/// @dev Uses AccessControl for multi-admin support with OPERATOR role
contract BellveProvisioner is AccessControl, ReentrancyGuard, RegistryConsumer {
    using SafeERC20 for IERC20;
    
    ////////////////////////////////////////////////////////////
    //                    Access Control                      //
    ////////////////////////////////////////////////////////////
    
    /// @notice Operator role for batch processing (indexer)
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    
    ////////////////////////////////////////////////////////////
    //                       Errors                           //
    ////////////////////////////////////////////////////////////
    
    error ZeroAddressOwner();
    error ZeroAddressToken();
    error AmountZero();
    error MinUnitsOutZero();
    error MinTokensOutZero();
    error DeadlineInPast();
    error AsyncDepositDisabled();
    error PriceBelowMinimum();
    error EmptyArray();
    error AlreadyResolved();
    error MixedTokensInBatch();
    error ArrayLengthMismatch();
    error MinUnitsNotMet();
    error InsufficientBalance();
    error WithdrawalExpired();
    error MinTokensNotMet();
    error DepositExpired();
    error InvalidDeposit();
    error InvalidWithdrawal();
    
    ////////////////////////////////////////////////////////////
    //                       Storage                          //
    ////////////////////////////////////////////////////////////
    
    /// @notice Configuration for each supported token
    mapping(IERC20 => TokenDetails) public tokenDetails;
    
    /// @notice Deposit hash to deposit request
    mapping(bytes32 => DepositRequest) public depositRequests;
    
    /// @notice Batch window to batch deposit details
    mapping(uint256 => BatchDeposit) public batchDeposits;
    
    /// @notice Deposit hash to batch hash mapping
    mapping(bytes32 => bytes32) public depositToBatch;
    
    /// @notice Withdrawal hash to withdrawal request
    mapping(bytes32 => WithdrawalRequest) public withdrawalRequests;
    
    /// @notice Batch window to batch withdrawal details
    mapping(uint256 => BatchWithdrawal) public withdrawalBatches;
    
    /// @notice Withdrawal hash to batch hash mapping
    mapping(bytes32 => bytes32) public withdrawalToBatch;
    
    /// @notice Track deposit hashes by batch window
    mapping(uint256 => bytes32[]) public batchWindowDeposits;
    
    /// @notice Track withdrawal hashes by batch window
    mapping(uint256 => bytes32[]) public batchWindowWithdrawals;
    
    /// @notice Batch window duration (in seconds)
    uint256 public constant BATCH_WINDOW_SIZE = 1 hours;
    
    /// @notice References to core contracts
    IBellveAccountNFT public accountNFT;
    BellveVault public vault;
    IPriceAndFeeCalculator public priceCalculator;
    
    ////////////////////////////////////////////////////////////
    //                       Events                           //
    ////////////////////////////////////////////////////////////
    
    event DepositRequested(
        bytes32 indexed depositHash,
        address indexed user,
        IERC20 indexed token,
        uint256 amount,
        uint256 minUnitsOut,
        uint256 batchWindow,
        uint8 riskProfile
    );
    
    event WithdrawalRequested(
        bytes32 indexed withdrawalHash,
        address indexed user,
        IERC20 indexed token,
        uint256 shares,
        uint256 minTokensOut,
        uint256 batchWindow,
        uint8 riskProfile
    );
    
    event BatchDepositSubmitted(
        uint256 indexed batchWindow,
        bytes32 indexed batchHash,
        uint256 totalAmount,
        uint256 depositCount
    );
    
    event BatchWithdrawalSubmitted(
        uint256 indexed batchWindow,
        bytes32 indexed batchHash,
        uint256 totalShares,
        uint256 withdrawalCount
    );
    
    event DepositResolved(
        bytes32 indexed depositHash,
        address indexed user,
        uint256 shares,
        uint256 batchWindow
    );
    
    event WithdrawalResolved(
        bytes32 indexed withdrawalHash,
        address indexed user,
        uint256 tokens,
        uint256 batchWindow
    );
    
    ////////////////////////////////////////////////////////////
    //                    Constructor                         //
    ////////////////////////////////////////////////////////////
    
    constructor(
        AddressRegistry _registry,
        address admin
    ) RegistryConsumer(_registry) {
        require(admin != address(0), "BellveProvisioner: Zero admin");
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(OPERATOR_ROLE, admin);
    }
    
    ////////////////////////////////////////////////////////////
    //                 Initialization                         //
    ////////////////////////////////////////////////////////////
    
    /// @notice Initialize contract references
    /// @param _accountNFT BellveAccountNFT address
    /// @param _vault BellveVault address
    /// @param _priceCalculator PriceCalculator address
    function initialize(
        address _accountNFT,
        address _vault,
        address _priceCalculator
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_accountNFT != address(0), "Zero accountNFT");
        require(_vault != address(0), "Zero vault");
        require(_priceCalculator != address(0), "Zero priceCalculator");
        
        accountNFT = IBellveAccountNFT(_accountNFT);
        vault = BellveVault(_vault);
        priceCalculator = IPriceAndFeeCalculator(_priceCalculator);
    }
    
    ////////////////////////////////////////////////////////////
    //                  Token Configuration                   //
    ////////////////////////////////////////////////////////////
    
    /// @notice Configure token settings
    /// @param token Token address
    /// @param asyncDepositEnabled Enable async deposits
    /// @param asyncRedeemEnabled Enable async redeems
    function configureToken(
        IERC20 token,
        bool asyncDepositEnabled,
        bool asyncRedeemEnabled
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenDetails[token] = TokenDetails({
            asyncDepositEnabled: asyncDepositEnabled,
            asyncRedeemEnabled: asyncRedeemEnabled,
            depositMultiplier: 10000,
            redeemMultiplier: 10000
        });
    }
    
    ////////////////////////////////////////////////////////////
    //                  User Deposit Flow                     //
    ////////////////////////////////////////////////////////////
    
    /// @notice Request async deposit
    /// @param token Token to deposit
    /// @param amount Amount to deposit
    /// @param minUnitsOut Minimum units expected
    /// @param deadline Deadline for request
    /// @param riskProfile Risk profile (0-2)
    /// @return depositHash Hash of the deposit request
    function requestDeposit(
        IERC20 token,
        uint256 amount,
        uint256 minUnitsOut,
        uint256 deadline,
        uint8 riskProfile
    ) external nonReentrant returns (bytes32) {
        if (amount == 0) revert AmountZero();
        if (minUnitsOut == 0) revert MinUnitsOutZero();
        if (deadline < block.timestamp) revert DeadlineInPast();
        if (!tokenDetails[token].asyncDepositEnabled) revert AsyncDepositDisabled();
        
        // Calculate batch window
        uint256 batchWindow = getCurrentBatchWindow();
        
        // Generate deposit hash
        bytes32 depositHash = keccak256(
            abi.encodePacked(msg.sender, address(token), amount, minUnitsOut, block.timestamp)
        );
        
        // Transfer tokens from user
        token.safeTransferFrom(msg.sender, address(this), amount);
        
        // Store deposit request
        depositRequests[depositHash] = DepositRequest({
            user: msg.sender,
            token: token,
            amount: amount,
            minUnitsOut: minUnitsOut,
            batchWindow: batchWindow,
            deadline: deadline,
            resolved: false,
            riskProfile: riskProfile
        });
        
        // Add to batch window tracking
        batchWindowDeposits[batchWindow].push(depositHash);
        
        // Ensure user has NFT
        if (accountNFT.balanceOf(msg.sender) == 0) {
            accountNFT.mintAccount(msg.sender);
        }
        
        // Update pending deposit on NFT
        uint256 currentPending = accountNFT.getPendingDeposit(msg.sender, riskProfile);
        accountNFT.setPendingDeposit(msg.sender, riskProfile, currentPending + amount);
        
        emit DepositRequested(depositHash, msg.sender, token, amount, minUnitsOut, batchWindow, riskProfile);
        
        return depositHash;
    }
    
    ////////////////////////////////////////////////////////////
    //                User Withdrawal Flow                    //
    ////////////////////////////////////////////////////////////
    
    /// @notice Request async withdrawal
    /// @param token Token to receive
    /// @param shares Amount of shares to redeem
    /// @param minTokensOut Minimum tokens expected
    /// @param deadline Deadline for request
    /// @param riskProfile Risk profile (0-2)
    /// @return withdrawalHash Hash of the withdrawal request
    function requestWithdrawal(
        IERC20 token,
        uint256 shares,
        uint256 minTokensOut,
        uint256 deadline,
        uint8 riskProfile
    ) external nonReentrant returns (bytes32) {
        if (shares == 0) revert AmountZero();
        if (minTokensOut == 0) revert MinTokensOutZero();
        if (deadline < block.timestamp) revert DeadlineInPast();
        
        // Check user has sufficient balance
        uint256 userBalance = accountNFT.getBalance(msg.sender, riskProfile);
        if (userBalance < shares) revert InsufficientBalance();
        
        // Calculate batch window
        uint256 batchWindow = getCurrentBatchWindow();
        
        // Generate withdrawal hash
        bytes32 withdrawalHash = keccak256(
            abi.encodePacked(msg.sender, address(token), shares, minTokensOut, block.timestamp)
        );
        
        // Store withdrawal request
        withdrawalRequests[withdrawalHash] = WithdrawalRequest({
            user: msg.sender,
            token: token,
            shares: shares,
            minTokensOut: minTokensOut,
            batchWindow: batchWindow,
            deadline: deadline,
            resolved: false,
            riskProfile: riskProfile
        });
        
        // Add to batch window tracking
        batchWindowWithdrawals[batchWindow].push(withdrawalHash);
        
        // Update pending withdrawal on NFT
        uint256 currentPending = accountNFT.getPendingWithdrawal(msg.sender, riskProfile);
        accountNFT.setPendingWithdrawal(msg.sender, riskProfile, currentPending + shares);
        
        // Debit shares from user
        accountNFT.debitShares(msg.sender, riskProfile, shares);
        
        emit WithdrawalRequested(withdrawalHash, msg.sender, token, shares, minTokensOut, batchWindow, riskProfile);
        
        return withdrawalHash;
    }
    
    ////////////////////////////////////////////////////////////
    //              Batch Processing (Operator)               //
    ////////////////////////////////////////////////////////////
    
    /// @notice Submit batch deposits for processing
    /// @param batchWindow Batch window to process
    /// @param depositHashes Array of deposit hashes in batch
    function submitBatchDeposits(
        uint256 batchWindow,
        bytes32[] calldata depositHashes
    ) external onlyRole(OPERATOR_ROLE) {
        if (depositHashes.length == 0) revert EmptyArray();
        
        uint256 totalAmount = 0;
        
        // Validate and sum deposits
        for (uint256 i = 0; i < depositHashes.length; i++) {
            DepositRequest storage request = depositRequests[depositHashes[i]];
            if (request.batchWindow != batchWindow) revert InvalidDeposit();
            if (request.resolved) revert AlreadyResolved();
            
            totalAmount += request.amount;
        }
        
        // Generate batch hash
        bytes32 batchHash = keccak256(abi.encodePacked(batchWindow, totalAmount, block.timestamp));
        
        // Store batch
        batchDeposits[batchWindow] = BatchDeposit({
            totalAmount: totalAmount,
            totalShares: 0,
            depositCount: depositHashes.length,
            resolved: false,
            submittedAt: block.timestamp,
            resolvedAt: 0,
            depositRequestHash: bytes32(0)
        });
        
        // Map deposits to batch
        for (uint256 i = 0; i < depositHashes.length; i++) {
            depositToBatch[depositHashes[i]] = batchHash;
        }
        
        emit BatchDepositSubmitted(batchWindow, batchHash, totalAmount, depositHashes.length);
    }
    
    /// @notice Resolve batch deposits and distribute shares
    /// @param batchWindow Batch window to resolve
    /// @param depositHashes Array of deposit hashes
    /// @param sharesPerDeposit Array of shares to distribute
    function resolveBatchDeposits(
        uint256 batchWindow,
        bytes32[] calldata depositHashes,
        uint256[] calldata sharesPerDeposit
    ) external onlyRole(OPERATOR_ROLE) {
        if (depositHashes.length != sharesPerDeposit.length) revert ArrayLengthMismatch();
        
        BatchDeposit storage batch = batchDeposits[batchWindow];
        if (batch.resolved) revert AlreadyResolved();
        
        uint256 totalShares = 0;
        
        // Distribute shares to users
        for (uint256 i = 0; i < depositHashes.length; i++) {
            DepositRequest storage request = depositRequests[depositHashes[i]];
            if (request.resolved) revert AlreadyResolved();
            
            uint256 shares = sharesPerDeposit[i];
            totalShares += shares;
            
            // Mark as resolved
            request.resolved = true;
            
            // Credit shares to user
            accountNFT.creditShares(request.user, request.riskProfile, shares);
            
            // Clear pending deposit
            uint256 currentPending = accountNFT.getPendingDeposit(request.user, request.riskProfile);
            if (currentPending >= request.amount) {
                accountNFT.setPendingDeposit(request.user, request.riskProfile, currentPending - request.amount);
            }
            
            emit DepositResolved(depositHashes[i], request.user, shares, batchWindow);
        }
        
        // Mark batch as resolved
        batch.resolved = true;
        batch.totalShares = totalShares;
        batch.resolvedAt = block.timestamp;
    }
    
    /// @notice Submit batch withdrawals for processing
    /// @param batchWindow Batch window to process
    /// @param withdrawalHashes Array of withdrawal hashes
    function submitBatchWithdrawals(
        uint256 batchWindow,
        bytes32[] calldata withdrawalHashes
    ) external onlyRole(OPERATOR_ROLE) {
        if (withdrawalHashes.length == 0) revert EmptyArray();
        
        uint256 totalShares = 0;
        
        // Validate and sum withdrawals
        for (uint256 i = 0; i < withdrawalHashes.length; i++) {
            WithdrawalRequest storage request = withdrawalRequests[withdrawalHashes[i]];
            if (request.batchWindow != batchWindow) revert InvalidWithdrawal();
            if (request.resolved) revert AlreadyResolved();
            
            totalShares += request.shares;
        }
        
        // Generate batch hash
        bytes32 batchHash = keccak256(abi.encodePacked(batchWindow, totalShares, block.timestamp));
        
        // Store batch
        withdrawalBatches[batchWindow] = BatchWithdrawal({
            totalShares: totalShares,
            totalTokens: 0,
            withdrawalCount: withdrawalHashes.length,
            resolved: false,
            submittedAt: block.timestamp,
            resolvedAt: 0,
            redeemRequestHash: bytes32(0)
        });
        
        // Map withdrawals to batch
        for (uint256 i = 0; i < withdrawalHashes.length; i++) {
            withdrawalToBatch[withdrawalHashes[i]] = batchHash;
        }
        
        emit BatchWithdrawalSubmitted(batchWindow, batchHash, totalShares, withdrawalHashes.length);
    }
    
    /// @notice Resolve batch withdrawals and distribute tokens
    /// @param batchWindow Batch window to resolve
    /// @param withdrawalHashes Array of withdrawal hashes
    /// @param tokensPerWithdrawal Array of tokens to distribute
    function resolveBatchWithdrawals(
        uint256 batchWindow,
        bytes32[] calldata withdrawalHashes,
        uint256[] calldata tokensPerWithdrawal
    ) external onlyRole(OPERATOR_ROLE) {
        if (withdrawalHashes.length != tokensPerWithdrawal.length) revert ArrayLengthMismatch();
        
        BatchWithdrawal storage batch = withdrawalBatches[batchWindow];
        if (batch.resolved) revert AlreadyResolved();
        
        uint256 totalTokens = 0;
        
        // Distribute tokens to users
        for (uint256 i = 0; i < withdrawalHashes.length; i++) {
            WithdrawalRequest storage request = withdrawalRequests[withdrawalHashes[i]];
            if (request.resolved) revert AlreadyResolved();
            
            uint256 tokens = tokensPerWithdrawal[i];
            totalTokens += tokens;
            
            // Mark as resolved
            request.resolved = true;
            
            // Transfer tokens to user
            request.token.safeTransfer(request.user, tokens);
            
            // Clear pending withdrawal
            uint256 currentPending = accountNFT.getPendingWithdrawal(request.user, request.riskProfile);
            if (currentPending >= request.shares) {
                accountNFT.setPendingWithdrawal(request.user, request.riskProfile, currentPending - request.shares);
            }
            
            emit WithdrawalResolved(withdrawalHashes[i], request.user, tokens, batchWindow);
        }
        
        // Mark batch as resolved
        batch.resolved = true;
        batch.totalTokens = totalTokens;
        batch.resolvedAt = block.timestamp;
    }
    
    ////////////////////////////////////////////////////////////
    //                  View Functions                        //
    ////////////////////////////////////////////////////////////
    
    /// @notice Get current batch window
    /// @return Current batch window timestamp
    function getCurrentBatchWindow() public view returns (uint256) {
        return (block.timestamp / BATCH_WINDOW_SIZE) * BATCH_WINDOW_SIZE;
    }
    
    /// @notice Get deposits in a batch window
    /// @param batchWindow Batch window
    /// @return Array of deposit hashes
    function getBatchWindowDeposits(uint256 batchWindow) external view returns (bytes32[] memory) {
        return batchWindowDeposits[batchWindow];
    }
    
    /// @notice Get withdrawals in a batch window
    /// @param batchWindow Batch window
    /// @return Array of withdrawal hashes
    function getBatchWindowWithdrawals(uint256 batchWindow) external view returns (bytes32[] memory) {
        return batchWindowWithdrawals[batchWindow];
    }
}

