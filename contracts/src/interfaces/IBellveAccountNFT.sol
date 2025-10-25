// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

/*
 * =====================================================================
 * Bellve Buildathon Prototype – TESTNET ONLY
 * =====================================================================
 */

import { IERC721 } from "@oz/token/ERC721/IERC721.sol";

/// @title IBellveAccountNFT
/// @notice Interface for Bellve Account NFT tracking user balances and operations
interface IBellveAccountNFT is IERC721 {
    
    /// @notice Get user's share balance for a specific risk profile
    /// @param user User address
    /// @param riskProfile Risk profile ID (0-2)
    /// @return Share balance
    function getBalance(address user, uint8 riskProfile) external view returns (uint256);
    
    /// @notice Credit shares to user (called by provisioner)
    /// @param user User address
    /// @param riskProfile Risk profile ID
    /// @param amount Amount of shares to credit
    function creditShares(address user, uint8 riskProfile, uint256 amount) external;
    
    /// @notice Debit shares from user (called by provisioner)
    /// @param user User address
    /// @param riskProfile Risk profile ID
    /// @param amount Amount of shares to debit
    function debitShares(address user, uint8 riskProfile, uint256 amount) external;
    
    /// @notice Get user's pending deposit amount
    /// @param user User address
    /// @param riskProfile Risk profile ID
    /// @return Pending deposit amount
    function getPendingDeposit(address user, uint8 riskProfile) external view returns (uint256);
    
    /// @notice Set pending deposit amount
    /// @param user User address
    /// @param riskProfile Risk profile ID
    /// @param amount Pending deposit amount
    function setPendingDeposit(address user, uint8 riskProfile, uint256 amount) external;
    
    /// @notice Get user's pending withdrawal shares
    /// @param user User address
    /// @param riskProfile Risk profile ID
    /// @return Pending withdrawal shares
    function getPendingWithdrawal(address user, uint8 riskProfile) external view returns (uint256);
    
    /// @notice Set pending withdrawal shares
    /// @param user User address
    /// @param riskProfile Risk profile ID
    /// @param shares Pending withdrawal shares
    function setPendingWithdrawal(address user, uint8 riskProfile, uint256 shares) external;
}

