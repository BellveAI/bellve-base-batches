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

/// @notice Token configuration for deposits and withdrawals
struct TokenDetails {
    /// @notice Whether async deposits are enabled
    bool asyncDepositEnabled;
    /// @notice Whether async redemptions are enabled
    bool asyncRedeemEnabled;
    /// @notice Deposit premium multiplier in basis points (10000 = 1.0x)
    uint16 depositMultiplier;
    /// @notice Redeem premium multiplier in basis points (10000 = 1.0x)
    uint16 redeemMultiplier;
}

/// @notice Individual deposit request details
struct DepositRequest {
    /// @notice User who made the deposit
    address user;
    /// @notice Token being deposited
    IERC20 token;
    /// @notice Amount of tokens deposited
    uint256 amount;
    /// @notice Minimum units expected to receive
    uint256 minUnitsOut;
    /// @notice Batch window this deposit belongs to
    uint256 batchWindow;
    /// @notice Timestamp when request expires
    uint256 deadline;
    /// @notice Whether this deposit has been resolved
    bool resolved;
    /// @notice Risk profile ID (0-2)
    uint8 riskProfile;
}

/// @notice Individual withdrawal request details
struct WithdrawalRequest {
    /// @notice User who made the withdrawal
    address user;
    /// @notice Token to receive
    IERC20 token;
    /// @notice Amount of shares to redeem
    uint256 shares;
    /// @notice Minimum tokens expected to receive
    uint256 minTokensOut;
    /// @notice Batch window this withdrawal belongs to
    uint256 batchWindow;
    /// @notice Timestamp when request expires
    uint256 deadline;
    /// @notice Whether this withdrawal has been resolved
    bool resolved;
    /// @notice Risk profile ID (0-2)
    uint8 riskProfile;
}

/// @notice Aggregated batch deposit information
struct BatchDeposit {
    /// @notice Total amount of tokens in batch
    uint256 totalAmount;
    /// @notice Total shares to be distributed
    uint256 totalShares;
    /// @notice Number of deposits in batch
    uint256 depositCount;
    /// @notice Whether batch has been resolved
    bool resolved;
    /// @notice Timestamp when batch was submitted
    uint256 submittedAt;
    /// @notice Timestamp when batch was resolved
    uint256 resolvedAt;
    /// @notice Hash of gtUSDa deposit request (if applicable)
    bytes32 depositRequestHash;
}

/// @notice Aggregated batch withdrawal information
struct BatchWithdrawal {
    /// @notice Total shares being redeemed
    uint256 totalShares;
    /// @notice Total tokens to be distributed
    uint256 totalTokens;
    /// @notice Number of withdrawals in batch
    uint256 withdrawalCount;
    /// @notice Whether batch has been resolved
    bool resolved;
    /// @notice Timestamp when batch was submitted
    uint256 submittedAt;
    /// @notice Timestamp when batch was resolved
    uint256 resolvedAt;
    /// @notice Hash of gtUSDa redeem request (if applicable)
    bytes32 redeemRequestHash;
}

