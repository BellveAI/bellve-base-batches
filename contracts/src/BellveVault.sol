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
import { Ownable } from "@oz/access/Ownable.sol";

/// @title BellveVault
/// @notice Simplified vault coordinator for Bellve system
/// @dev Acts as a registry and coordinator without maintaining ERC20 balances
contract BellveVault is Ownable {
    using SafeERC20 for IERC20;
    
    ////////////////////////////////////////////////////////////
    //                       Storage                          //
    ////////////////////////////////////////////////////////////
    
    /// @notice Address authorized to manage vault operations (BellveProvisioner)
    address public provisioner;
    
    /// @notice Mapping of supported tokens
    mapping(address => bool) public supportedTokens;
    
    /// @notice Vault name
    string public name;
    
    /// @notice Vault symbol
    string public symbol;
    
    ////////////////////////////////////////////////////////////
    //                       Events                           //
    ////////////////////////////////////////////////////////////
    
    event Deposit(
        address indexed user,
        address indexed recipient,
        IERC20 indexed token,
        uint256 tokenAmount,
        uint256 sharesAmount
    );
    
    event Withdraw(
        address indexed user,
        address indexed recipient,
        IERC20 indexed token,
        uint256 tokenAmount,
        uint256 sharesAmount
    );
    
    event ProvisionerSet(address indexed oldProvisioner, address indexed newProvisioner);
    event TokenSupportUpdated(IERC20 indexed token, bool supported);
    
    ////////////////////////////////////////////////////////////
    //                      Modifiers                         //
    ////////////////////////////////////////////////////////////
    
    modifier onlyProvisioner() {
        require(msg.sender == provisioner, "BellveVault: Only provisioner");
        _;
    }
    
    ////////////////////////////////////////////////////////////
    //                    Constructor                         //
    ////////////////////////////////////////////////////////////
    
    constructor(
        string memory _name,
        string memory _symbol,
        address initialOwner
    ) Ownable(initialOwner) {
        name = _name;
        symbol = _symbol;
    }
    
    ////////////////////////////////////////////////////////////
    //                  Admin Functions                       //
    ////////////////////////////////////////////////////////////
    
    /// @notice Set the provisioner address
    /// @param _provisioner New provisioner address
    function setProvisioner(address _provisioner) external onlyOwner {
        require(_provisioner != address(0), "BellveVault: Zero address");
        address oldProvisioner = provisioner;
        provisioner = _provisioner;
        emit ProvisionerSet(oldProvisioner, _provisioner);
    }
    
    /// @notice Update token support status
    /// @param token Token address
    /// @param supported Whether token is supported
    function setTokenSupport(IERC20 token, bool supported) external onlyOwner {
        supportedTokens[address(token)] = supported;
        emit TokenSupportUpdated(token, supported);
    }
    
    ////////////////////////////////////////////////////////////
    //                 Coordination Functions                 //
    ////////////////////////////////////////////////////////////
    
    /// @notice Emit deposit event (called by provisioner)
    /// @param user User making deposit
    /// @param recipient Recipient of shares
    /// @param token Token being deposited
    /// @param tokenAmount Amount of tokens
    /// @param sharesAmount Amount of shares
    function emitDeposit(
        address user,
        address recipient,
        IERC20 token,
        uint256 tokenAmount,
        uint256 sharesAmount
    ) external onlyProvisioner {
        emit Deposit(user, recipient, token, tokenAmount, sharesAmount);
    }
    
    /// @notice Emit withdraw event (called by provisioner)
    /// @param user User making withdrawal
    /// @param recipient Recipient of tokens
    /// @param token Token being withdrawn
    /// @param tokenAmount Amount of tokens
    /// @param sharesAmount Amount of shares
    function emitWithdraw(
        address user,
        address recipient,
        IERC20 token,
        uint256 tokenAmount,
        uint256 sharesAmount
    ) external onlyProvisioner {
        emit Withdraw(user, recipient, token, tokenAmount, sharesAmount);
    }
}

