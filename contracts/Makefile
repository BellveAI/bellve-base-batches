.PHONY: build test deploy verify clean install

# Build contracts
build:
	@echo "🔨 Building contracts..."
	forge build

# Run tests
test:
	@echo "🧪 Running tests..."
	forge test -vv

# Run tests with gas report
test-gas:
	@echo "⛽ Running tests with gas report..."
	forge test --gas-report

# Run tests with coverage
coverage:
	@echo "📊 Running coverage..."
	forge coverage

# Deploy to Base Sepolia
deploy:
	@echo "🚀 Deploying to Base Sepolia (TESTNET ONLY)..."
	@echo "⚠️  WARNING: This is a TESTNET deployment for evaluation purposes only"
	forge script script/DeployBellve.s.sol:DeployBellve \
		--rpc-url base_sepolia \
		--broadcast \
		--verify \
		-vvvv

# Deploy without verification
deploy-no-verify:
	@echo "🚀 Deploying to Base Sepolia without verification..."
	forge script script/DeployBellve.s.sol:DeployBellve \
		--rpc-url base_sepolia \
		--broadcast \
		-vvvv

# Verify contracts on Etherscan
verify:
	@echo "✅ Verifying contracts on Basescan..."
	@echo "Run this manually with specific addresses after deployment"

# Format code
fmt:
	@echo "🎨 Formatting code..."
	forge fmt

# Check formatting
fmt-check:
	@echo "🔍 Checking formatting..."
	forge fmt --check

# Clean build artifacts
clean:
	@echo "🧹 Cleaning..."
	forge clean
	rm -rf out cache

# Install dependencies
install:
	@echo "📦 Installing dependencies..."
	forge install foundry-rs/forge-std@v1.9.5 --no-commit
	forge install OpenZeppelin/openzeppelin-contracts@v5.1.0 --no-commit

# Update dependencies
update:
	@echo "🔄 Updating dependencies..."
	forge update

# Snapshot gas usage
snapshot:
	@echo "📸 Creating gas snapshot..."
	forge snapshot

# Help
help:
	@echo "Bellve Buildathon - Foundry Makefile"
	@echo ""
	@echo "Available commands:"
	@echo "  make build          - Build all contracts"
	@echo "  make test           - Run all tests"
	@echo "  make test-gas       - Run tests with gas reporting"
	@echo "  make coverage       - Generate coverage report"
	@echo "  make deploy         - Deploy to Base Sepolia with verification"
	@echo "  make verify         - Verify contracts (after deployment)"
	@echo "  make fmt            - Format all Solidity files"
	@echo "  make fmt-check      - Check formatting"
	@echo "  make clean          - Remove build artifacts"
	@echo "  make install        - Install Foundry dependencies"
	@echo "  make snapshot       - Create gas snapshot"

