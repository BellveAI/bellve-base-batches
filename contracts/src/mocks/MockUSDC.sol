// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

/*
 * =====================================================================
 * Bellve Buildathon Prototype – TESTNET ONLY
 * =====================================================================
 */

import { ERC20 } from "@oz/token/ERC20/ERC20.sol";

/// @title MockUSDC
/// @notice Mock USDC token for testing purposes
contract MockUSDC is ERC20 {
    
    constructor() ERC20("Mock USDC", "USDC") {}
    
    /// @notice Mint tokens for testing
    /// @param to Recipient address
    /// @param amount Amount to mint
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
    
    /// @notice Returns 6 decimals like real USDC
    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

