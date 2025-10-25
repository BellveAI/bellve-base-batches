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

import { ERC721 } from "@oz/token/ERC721/ERC721.sol";
import { Ownable } from "@oz/access/Ownable.sol";
import { IBellveAccountNFT } from "./interfaces/IBellveAccountNFT.sol";

/// @title BellveAccountNFT
/// @notice Soulbound NFT tracking user balances and operations across risk profiles
/// @dev Simplified version for buildathon - tracks balances per risk profile
contract BellveAccountNFT is ERC721, Ownable, IBellveAccountNFT {
    
    ////////////////////////////////////////////////////////////
    //                       Storage                          //
    ////////////////////////////////////////////////////////////
    
    /// @notice Current token ID counter
    uint256 private _currentTokenId;
    
    /// @notice User address to token ID mapping
    mapping(address => uint256) public userToTokenId;
    
    /// @notice Token ID locked status (soulbound)
    mapping(uint256 => bool) private _locked;
    
    /// @notice User balances per risk profile
    /// tokenId => riskProfile => balance
    mapping(uint256 => mapping(uint8 => uint256)) public balances;
    
    /// @notice Pending deposits per risk profile  
    /// tokenId => riskProfile => pending amount
    mapping(uint256 => mapping(uint8 => uint256)) public pendingDeposits;
    
    /// @notice Pending withdrawals per risk profile
    /// tokenId => riskProfile => pending shares
    mapping(uint256 => mapping(uint8 => uint256)) public pendingWithdrawals;
    
    /// @notice Account metadata
    mapping(uint256 => AccountMetadata) public accountMetadata;
    
    struct AccountMetadata {
        uint256 memberSince;
        uint256 totalDeposited;
        uint256 totalWithdrawn;
        uint256 lastActivity;
    }
    
    ////////////////////////////////////////////////////////////
    //                       Events                           //
    ////////////////////////////////////////////////////////////
    
    event AccountCreated(address indexed user, uint256 indexed tokenId);
    event SharesCredited(address indexed user, uint8 indexed riskProfile, uint256 amount);
    event SharesDebited(address indexed user, uint8 indexed riskProfile, uint256 amount);
    event Locked(uint256 indexed tokenId);
    
    ////////////////////////////////////////////////////////////
    //                    Constructor                         //
    ////////////////////////////////////////////////////////////
    
    constructor(address initialOwner) 
        ERC721("Bellve Account NFT", "BELLVE")
        Ownable(initialOwner)
    {
        _currentTokenId = 0;
    }
    
    ////////////////////////////////////////////////////////////
    //                  Minting Functions                     //
    ////////////////////////////////////////////////////////////
    
    /// @notice Mint a new account NFT for a user
    /// @param user User address
    /// @return tokenId The minted token ID
    function mintAccount(address user) external onlyOwner returns (uint256) {
        require(userToTokenId[user] == 0, "BellveAccountNFT: Account exists");
        
        uint256 tokenId = ++_currentTokenId;
        _mint(user, tokenId);
        
        userToTokenId[user] = tokenId;
        _locked[tokenId] = true;
        
        accountMetadata[tokenId] = AccountMetadata({
            memberSince: block.timestamp,
            totalDeposited: 0,
            totalWithdrawn: 0,
            lastActivity: block.timestamp
        });
        
        emit AccountCreated(user, tokenId);
        emit Locked(tokenId);
        
        return tokenId;
    }
    
    ////////////////////////////////////////////////////////////
    //                  Balance Management                    //
    ////////////////////////////////////////////////////////////
    
    /// @notice Get user's share balance for a risk profile
    /// @param user User address
    /// @param riskProfile Risk profile ID (0-2)
    /// @return Share balance
    function getBalance(address user, uint8 riskProfile) external view returns (uint256) {
        uint256 tokenId = userToTokenId[user];
        if (tokenId == 0) return 0;
        return balances[tokenId][riskProfile];
    }
    
    /// @notice Credit shares to user (only owner/provisioner)
    /// @param user User address
    /// @param riskProfile Risk profile ID
    /// @param amount Amount to credit
    function creditShares(address user, uint8 riskProfile, uint256 amount) external onlyOwner {
        uint256 tokenId = userToTokenId[user];
        require(tokenId != 0, "BellveAccountNFT: No account");
        
        balances[tokenId][riskProfile] += amount;
        accountMetadata[tokenId].lastActivity = block.timestamp;
        
        emit SharesCredited(user, riskProfile, amount);
    }
    
    /// @notice Debit shares from user (only owner/provisioner)
    /// @param user User address
    /// @param riskProfile Risk profile ID
    /// @param amount Amount to debit
    function debitShares(address user, uint8 riskProfile, uint256 amount) external onlyOwner {
        uint256 tokenId = userToTokenId[user];
        require(tokenId != 0, "BellveAccountNFT: No account");
        require(balances[tokenId][riskProfile] >= amount, "BellveAccountNFT: Insufficient balance");
        
        balances[tokenId][riskProfile] -= amount;
        accountMetadata[tokenId].lastActivity = block.timestamp;
        
        emit SharesDebited(user, riskProfile, amount);
    }
    
    ////////////////////////////////////////////////////////////
    //                 Pending Operations                     //
    ////////////////////////////////////////////////////////////
    
    /// @notice Get pending deposit amount
    /// @param user User address
    /// @param riskProfile Risk profile ID
    /// @return Pending deposit amount
    function getPendingDeposit(address user, uint8 riskProfile) external view returns (uint256) {
        uint256 tokenId = userToTokenId[user];
        if (tokenId == 0) return 0;
        return pendingDeposits[tokenId][riskProfile];
    }
    
    /// @notice Set pending deposit amount (only owner/provisioner)
    /// @param user User address
    /// @param riskProfile Risk profile ID
    /// @param amount Pending amount
    function setPendingDeposit(address user, uint8 riskProfile, uint256 amount) external onlyOwner {
        uint256 tokenId = userToTokenId[user];
        require(tokenId != 0, "BellveAccountNFT: No account");
        
        pendingDeposits[tokenId][riskProfile] = amount;
        accountMetadata[tokenId].lastActivity = block.timestamp;
    }
    
    /// @notice Get pending withdrawal shares
    /// @param user User address
    /// @param riskProfile Risk profile ID
    /// @return Pending withdrawal shares
    function getPendingWithdrawal(address user, uint8 riskProfile) external view returns (uint256) {
        uint256 tokenId = userToTokenId[user];
        if (tokenId == 0) return 0;
        return pendingWithdrawals[tokenId][riskProfile];
    }
    
    /// @notice Set pending withdrawal shares (only owner/provisioner)
    /// @param user User address
    /// @param riskProfile Risk profile ID
    /// @param shares Pending shares
    function setPendingWithdrawal(address user, uint8 riskProfile, uint256 shares) external onlyOwner {
        uint256 tokenId = userToTokenId[user];
        require(tokenId != 0, "BellveAccountNFT: No account");
        
        pendingWithdrawals[tokenId][riskProfile] = shares;
        accountMetadata[tokenId].lastActivity = block.timestamp;
    }
    
    ////////////////////////////////////////////////////////////
    //                 Soulbound Overrides                    //
    ////////////////////////////////////////////////////////////
    
    /// @notice Check if token is locked (soulbound)
    /// @param tokenId Token ID
    /// @return True if locked
    function locked(uint256 tokenId) external view returns (bool) {
        return _locked[tokenId];
    }
    
    /// @notice Override transfer to prevent transfers (soulbound)
    function _update(address to, uint256 tokenId, address auth)
        internal
        virtual
        override
        returns (address)
    {
        address from = _ownerOf(tokenId);
        
        // Allow minting (from == address(0))
        if (from == address(0)) {
            return super._update(to, tokenId, auth);
        }
        
        // Block all transfers for soulbound tokens
        require(!_locked[tokenId], "BellveAccountNFT: Soulbound token");
        
        return super._update(to, tokenId, auth);
    }
}

