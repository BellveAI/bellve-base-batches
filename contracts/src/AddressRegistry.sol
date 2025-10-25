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

import { AccessControl } from "@oz/access/AccessControl.sol";

/// @title AddressRegistry
/// @notice Centralized registry for all Bellve system contract addresses
/// @dev Eliminates circular dependencies by providing a single source of truth
contract AddressRegistry is AccessControl {
    
    ////////////////////////////////////////////////////////////
    //                        Roles                           //
    ////////////////////////////////////////////////////////////
    
    /// @notice Role for managing registry addresses
    bytes32 public constant REGISTRY_ADMIN_ROLE = keccak256("REGISTRY_ADMIN_ROLE");
    
    ////////////////////////////////////////////////////////////
    //                       Storage                          //
    ////////////////////////////////////////////////////////////
    
    /// @notice Mapping of contract name to address
    mapping(string => address) private _addresses;
    
    /// @notice Version counter for cache invalidation
    uint256 public version;
    
    ////////////////////////////////////////////////////////////
    //                       Events                           //
    ////////////////////////////////////////////////////////////
    
    /// @notice Emitted when an address is registered or updated
    event AddressUpdated(string indexed name, address indexed oldAddress, address indexed newAddress, uint256 version);
    
    ////////////////////////////////////////////////////////////
    //                    Constructor                         //
    ////////////////////////////////////////////////////////////
    
    /// @notice Initialize the registry with default admin
    /// @param admin Address to be granted REGISTRY_ADMIN_ROLE
    constructor(address admin) {
        require(admin != address(0), "AddressRegistry: Zero address admin");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(REGISTRY_ADMIN_ROLE, admin);
        version = 1;
    }
    
    ////////////////////////////////////////////////////////////
    //                  Core Functions                        //
    ////////////////////////////////////////////////////////////
    
    /// @notice Register or update a contract address
    /// @param name Contract name identifier (e.g., "BELLVE_PROVISIONER")
    /// @param contractAddress Address of the contract
    function setAddress(string calldata name, address contractAddress) 
        external 
        onlyRole(REGISTRY_ADMIN_ROLE) 
    {
        require(bytes(name).length > 0, "AddressRegistry: Empty name");
        require(contractAddress != address(0), "AddressRegistry: Zero address");
        
        address oldAddress = _addresses[name];
        _addresses[name] = contractAddress;
        version++;
        
        emit AddressUpdated(name, oldAddress, contractAddress, version);
    }
    
    /// @notice Register multiple addresses in a single transaction
    /// @param names Array of contract name identifiers
    /// @param addresses Array of contract addresses
    function setAddresses(string[] calldata names, address[] calldata addresses)
        external
        onlyRole(REGISTRY_ADMIN_ROLE)
    {
        require(names.length == addresses.length, "AddressRegistry: Length mismatch");
        require(names.length > 0, "AddressRegistry: Empty arrays");
        
        for (uint256 i = 0; i < names.length; i++) {
            require(bytes(names[i]).length > 0, "AddressRegistry: Empty name");
            require(addresses[i] != address(0), "AddressRegistry: Zero address");
            
            address oldAddress = _addresses[names[i]];
            _addresses[names[i]] = addresses[i];
            
            emit AddressUpdated(names[i], oldAddress, addresses[i], version + 1);
        }
        
        version++;
    }
    
    /// @notice Get contract address by name
    /// @param name Contract name identifier
    /// @return Contract address (zero if not found)
    function getAddress(string calldata name) external view returns (address) {
        return _addresses[name];
    }
    
    /// @notice Check if an address is registered
    /// @param name Contract name identifier
    /// @return True if address is registered and non-zero
    function hasAddress(string calldata name) external view returns (bool) {
        return _addresses[name] != address(0);
    }
    
    ////////////////////////////////////////////////////////////
    //                 Registry Constants                     //
    ////////////////////////////////////////////////////////////
    
    string public constant MOCK_USDC = "MOCK_USDC";
    string public constant MOCK_GTUSDA = "MOCK_GTUSDA";
    string public constant PRICE_CALCULATOR = "PRICE_CALCULATOR";
    string public constant BELLVE_VAULT = "BELLVE_VAULT";
    string public constant BELLVE_ACCOUNT_NFT = "BELLVE_ACCOUNT_NFT";
    string public constant BELLVE_PROVISIONER = "BELLVE_PROVISIONER";
}

