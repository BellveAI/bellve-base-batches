// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

/*
 * =====================================================================
 * Bellve Buildathon Prototype – TESTNET ONLY
 * =====================================================================
 */

import { IPriceAndFeeCalculator } from "../interfaces/IPriceAndFeeCalculator.sol";

/// @title MockPriceCalculator
/// @notice Mock price calculator returning fixed exchange rates
contract MockPriceCalculator is IPriceAndFeeCalculator {
    
    /// @notice Fixed exchange rate (1:1 for simplicity)
    uint256 public constant EXCHANGE_RATE = 1e18;
    
    /// @notice Get exchange rate from tokens to units
    /// @param tokensIn Amount of tokens
    /// @return unitsOut Amount of units
    function tokensToUnits(uint256 tokensIn) external pure returns (uint256 unitsOut) {
        // 1 USDC (6 decimals) = 1 unit (18 decimals equivalent)
        // Scale up from 6 to 18 decimals
        return tokensIn * 1e12;
    }
    
    /// @notice Get exchange rate from units to tokens
    /// @param unitsIn Amount of units
    /// @return tokensOut Amount of tokens
    function unitsToTokens(uint256 unitsIn) external pure returns (uint256 tokensOut) {
        // 1 unit (18 decimals) = 1 USDC (6 decimals)
        // Scale down from 18 to 6 decimals
        return unitsIn / 1e12;
    }
}

