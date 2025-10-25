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

import { AddressRegistry } from "./AddressRegistry.sol";

/// @title RegistryConsumer
/// @notice Base contract for consuming AddressRegistry with caching
/// @dev Provides gas-efficient cached access to registry addresses
abstract contract RegistryConsumer {
    
    ////////////////////////////////////////////////////////////
    //                       Storage                          //
    ////////////////////////////////////////////////////////////
    
    /// @notice The centralized address registry
    AddressRegistry public immutable registry;
    
    /// @notice Cached addresses for gas efficiency
    mapping(string => address) private _cachedAddresses;
    
    /// @notice Last synced registry version
    uint256 private _lastSyncVersion;
    
    ////////////////////////////////////////////////////////////
    //                       Events                           //
    ////////////////////////////////////////////////////////////
    
    /// @notice Emitted when addresses are synced from registry
    event AddressesSynced(uint256 fromVersion, uint256 toVersion);
    
    ////////////////////////////////////////////////////////////
    //                    Constructor                         //
    ////////////////////////////////////////////////////////////
    
    /// @notice Initialize with registry reference
    /// @param registry_ The AddressRegistry contract
    constructor(AddressRegistry registry_) {
        require(address(registry_) != address(0), "RegistryConsumer: Zero registry");
        registry = registry_;
        _lastSyncVersion = 0;
    }
    
    ////////////////////////////////////////////////////////////
    //                  Cache Management                      //
    ////////////////////////////////////////////////////////////
    
    /// @notice Sync cached addresses with registry if version is stale
    function syncAddresses() public {
        uint256 currentVersion = registry.version();
        if (currentVersion > _lastSyncVersion) {
            _syncAddressesFromRegistry();
            emit AddressesSynced(_lastSyncVersion, currentVersion);
            _lastSyncVersion = currentVersion;
        }
    }
    
    /// @notice Get cached address by name
    /// @param name Contract name identifier
    /// @return Cached contract address
    function getAddress(string memory name) public returns (address) {
        syncAddresses();
        return _cachedAddresses[name];
    }
    
    ////////////////////////////////////////////////////////////
    //                 Internal Functions                     //
    ////////////////////////////////////////////////////////////
    
    /// @notice Internal function to sync addresses from registry
    /// @dev Override in child contracts to specify which addresses to cache
    function _syncAddressesFromRegistry() internal virtual {
        _cachedAddresses[registry.MOCK_USDC()] = registry.getAddress(registry.MOCK_USDC());
        _cachedAddresses[registry.MOCK_GTUSDA()] = registry.getAddress(registry.MOCK_GTUSDA());
        _cachedAddresses[registry.PRICE_CALCULATOR()] = registry.getAddress(registry.PRICE_CALCULATOR());
        _cachedAddresses[registry.BELLVE_VAULT()] = registry.getAddress(registry.BELLVE_VAULT());
        _cachedAddresses[registry.BELLVE_ACCOUNT_NFT()] = registry.getAddress(registry.BELLVE_ACCOUNT_NFT());
        _cachedAddresses[registry.BELLVE_PROVISIONER()] = registry.getAddress(registry.BELLVE_PROVISIONER());
    }
}

