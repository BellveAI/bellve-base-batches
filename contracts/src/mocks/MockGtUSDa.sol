// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

/*
 * =====================================================================
 * Bellve Buildathon Prototype – TESTNET ONLY
 * =====================================================================
 */

import { ERC20 } from "@oz/token/ERC20/ERC20.sol";
import { IERC20 } from "@oz/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@oz/token/ERC20/utils/SafeERC20.sol";

/// @title MockGtUSDa
/// @notice Mock gtUSDa vault with async deposit/redeem pattern
/// @dev Simulates Aera-style async operations for testing
contract MockGtUSDa is ERC20 {
    using SafeERC20 for IERC20;
    
    ////////////////////////////////////////////////////////////
    //                       Storage                          //
    ////////////////////////////////////////////////////////////
    
    /// @notice Asset token (USDC)
    IERC20 public immutable asset;
    
    /// @notice Pending deposit requests
    mapping(bytes32 => DepositRequest) public depositRequests;
    
    /// @notice Pending redeem requests
    mapping(bytes32 => RedeemRequest) public redeemRequests;
    
    /// @notice Exchange rate (units of asset per share, scaled by 1e18)
    uint256 public exchangeRate = 1e18;
    
    struct DepositRequest {
        address depositor;
        uint256 assets;
        bool resolved;
    }
    
    struct RedeemRequest {
        address redeemer;
        uint256 shares;
        bool resolved;
    }
    
    ////////////////////////////////////////////////////////////
    //                       Events                           //
    ////////////////////////////////////////////////////////////
    
    event DepositRequested(
        bytes32 indexed requestHash,
        address indexed depositor,
        uint256 assets
    );
    
    event DepositResolved(
        bytes32 indexed requestHash,
        address indexed depositor,
        uint256 assets,
        uint256 shares
    );
    
    event RedeemRequested(
        bytes32 indexed requestHash,
        address indexed redeemer,
        uint256 shares
    );
    
    event RedeemResolved(
        bytes32 indexed requestHash,
        address indexed redeemer,
        uint256 shares,
        uint256 assets
    );
    
    ////////////////////////////////////////////////////////////
    //                    Constructor                         //
    ////////////////////////////////////////////////////////////
    
    constructor(IERC20 _asset) ERC20("Mock gtUSDa", "gtUSDa") {
        asset = _asset;
    }
    
    ////////////////////////////////////////////////////////////
    //                 Async Deposit Flow                     //
    ////////////////////////////////////////////////////////////
    
    /// @notice Request async deposit
    /// @param assets Amount of assets to deposit
    /// @return requestHash Hash of the deposit request
    function requestDeposit(uint256 assets) external returns (bytes32) {
        require(assets > 0, "MockGtUSDa: Zero assets");
        
        // Generate unique request hash
        bytes32 requestHash = keccak256(
            abi.encodePacked(msg.sender, assets, block.timestamp, blockhash(block.number - 1))
        );
        
        // Transfer assets from depositor
        asset.safeTransferFrom(msg.sender, address(this), assets);
        
        // Store request
        depositRequests[requestHash] = DepositRequest({
            depositor: msg.sender,
            assets: assets,
            resolved: false
        });
        
        emit DepositRequested(requestHash, msg.sender, assets);
        
        return requestHash;
    }
    
    /// @notice Resolve deposit request (simulate async resolution)
    /// @param requestHash Hash of the deposit request
    function resolveDeposit(bytes32 requestHash) external {
        DepositRequest storage request = depositRequests[requestHash];
        require(request.assets > 0, "MockGtUSDa: Invalid request");
        require(!request.resolved, "MockGtUSDa: Already resolved");
        
        // Mark as resolved
        request.resolved = true;
        
        // Calculate shares (using exchange rate)
        uint256 shares = (request.assets * 1e18) / exchangeRate;
        
        // Mint shares to depositor
        _mint(request.depositor, shares);
        
        emit DepositResolved(requestHash, request.depositor, request.assets, shares);
    }
    
    ////////////////////////////////////////////////////////////
    //                 Async Redeem Flow                      //
    ////////////////////////////////////////////////////////////
    
    /// @notice Request async redeem
    /// @param shares Amount of shares to redeem
    /// @return requestHash Hash of the redeem request
    function requestRedeem(uint256 shares) external returns (bytes32) {
        require(shares > 0, "MockGtUSDa: Zero shares");
        require(balanceOf(msg.sender) >= shares, "MockGtUSDa: Insufficient balance");
        
        // Generate unique request hash
        bytes32 requestHash = keccak256(
            abi.encodePacked(msg.sender, shares, block.timestamp, blockhash(block.number - 1))
        );
        
        // Burn shares from redeemer
        _burn(msg.sender, shares);
        
        // Store request
        redeemRequests[requestHash] = RedeemRequest({
            redeemer: msg.sender,
            shares: shares,
            resolved: false
        });
        
        emit RedeemRequested(requestHash, msg.sender, shares);
        
        return requestHash;
    }
    
    /// @notice Resolve redeem request (simulate async resolution)
    /// @param requestHash Hash of the redeem request
    function resolveRedeem(bytes32 requestHash) external {
        RedeemRequest storage request = redeemRequests[requestHash];
        require(request.shares > 0, "MockGtUSDa: Invalid request");
        require(!request.resolved, "MockGtUSDa: Already resolved");
        
        // Mark as resolved
        request.resolved = true;
        
        // Calculate assets (using exchange rate)
        uint256 assets = (request.shares * exchangeRate) / 1e18;
        
        // Transfer assets to redeemer
        asset.safeTransfer(request.redeemer, assets);
        
        emit RedeemResolved(requestHash, request.redeemer, request.shares, assets);
    }
    
    ////////////////////////////////////////////////////////////
    //                 Admin Functions                        //
    ////////////////////////////////////////////////////////////
    
    /// @notice Set exchange rate for testing
    /// @param newRate New exchange rate (scaled by 1e18)
    function setExchangeRate(uint256 newRate) external {
        require(newRate > 0, "MockGtUSDa: Zero rate");
        exchangeRate = newRate;
    }
    
    /// @notice Get decimals (18 for gtUSDa)
    function decimals() public pure override returns (uint8) {
        return 18;
    }
}

