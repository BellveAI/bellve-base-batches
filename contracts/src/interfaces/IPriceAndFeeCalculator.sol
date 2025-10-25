// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

/*
 * =====================================================================
 * Bellve Buildathon Prototype – TESTNET ONLY
 * =====================================================================
 */

/// @title IPriceAndFeeCalculator
/// @notice Interface for price and fee calculations
interface IPriceAndFeeCalculator {
    
    /// @notice Get exchange rate from tokens to units
    /// @param tokensIn Amount of tokens
    /// @return unitsOut Amount of units (scaled by 1e18)
    function tokensToUnits(uint256 tokensIn) external view returns (uint256 unitsOut);
    
    /// @notice Get exchange rate from units to tokens
    /// @param unitsIn Amount of units
    /// @return tokensOut Amount of tokens
    function unitsToTokens(uint256 unitsIn) external view returns (uint256 tokensOut);
}

