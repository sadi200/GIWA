#!/bin/bash

# GIWA Bridge UI Script
# Created by Earnpoint
# Logo by SADI

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function to display the header with logo
show_header() {
    clear
    echo -e "${BLUE}"
    echo "   ____ _       _        ____            _     _ "
    echo "  / ___(_) __ _| | ___  | __ ) _ __ __ _(_) __| |"
    echo " | |  _| |/ _\` | |/ _ \ |  _ \| '__/ _\` | |/ _\` |"
    echo " | |_| | | (_| | |  __/ | |_) | | | (_| | | (_| |"
    echo "  \____|_|\__, |_|\___| |____/|_|  \__,_|_|\__,_|"
    echo "          |___/                                  "
    echo -e "${NC}"
    echo -e "${YELLOW}           BRIDGING ETHEREUM SEPOLIA <-> GIWA${NC}"
    echo -e "${GREEN}                   Created by Earnpoint${NC}"
    echo -e "${BLUE}                     Logo by SADI${NC}"
    echo "=================================================="
    echo
}

# Function to check if we're in a writable directory
check_writable_dir() {
    if [ ! -w "$SCRIPT_DIR" ]; then
        echo -e "${RED}Current directory is not writable.${NC}"
        echo -e "${YELLOW}Please run this script from a directory where you have write permissions.${NC}"
        exit 1
    fi
}

# Function to check if Node.js is installed
check_node() {
    if ! command -v node &> /dev/null; then
        echo -e "${RED}Node.js is not installed.${NC}"
        echo "Please install Node.js from https://nodejs.org/"
        exit 1
    fi
}

# Function to check if pnpm is installed
check_pnpm() {
    if ! command -v pnpm &> /dev/null; then
        echo -e "${RED}pnpm is not installed.${NC}"
        echo "Installing pnpm..."
        npm install -g pnpm
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to install pnpm. Please install it manually.${NC}"
            exit 1
        fi
        echo -e "${GREEN}pnpm installed successfully.${NC}"
    fi
}

# Function to create all necessary files
create_files() {
    echo -e "${YELLOW}Creating project structure...${NC}"
    
    # Create config.ts
    cat > config.ts << 'EOF'
// config.ts
import { defineChain, createPublicClient, createWalletClient, http } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { publicActionsL1, publicActionsL2, walletActionsL1, walletActionsL2 } from "viem/op-stack";
import { sepolia } from "viem/chains";
import dotenv from "dotenv";

dotenv.config();

if (!process.env.TEST_PRIVATE_KEY) {
  throw new Error("Set TEST_PRIVATE_KEY in .env");
}

export const PRIVATE_KEY = process.env.TEST_PRIVATE_KEY as `0x${string}`;
export const account = privateKeyToAccount(PRIVATE_KEY);

// GIWA Sepolia chain config (values from Giwa docs)
export const giwaSepolia = defineChain({
  id: 91342,
  name: "Giwa Sepolia",
  network: "giwa-sepolia",
  nativeCurrency: { name: "Sepolia Ether", symbol: "ETH", decimals: 18 },
  rpcUrls: {
    default: { http: ["https://sepolia-rpc.giwa.io"] },
  },
  contracts: {
    multicall3: { address: "0xcA11bde05977b3631167028862bE2a173976CA11" },
    l2OutputOracle: {},
    disputeGameFactory: {
      [sepolia.id]: { address: "0x37347caB2afaa49B776372279143D71ad1f354F6" },
    },
    portal: {
      [sepolia.id]: { address: "0x956962C34687A954e611A83619ABaA37Ce6bC78A" },
    },
    l1StandardBridge: {
      [sepolia.id]: { address: "0x77b2ffc0F57598cAe1DB76cb398059cF5d10A7E7" },
    },
  },
  testnet: true,
});

// Public client L1 (Ethereum Sepolia)
export const publicClientL1 = createPublicClient({
  chain: sepolia,
  transport: http(),
}).extend(publicActionsL1());

// Wallet client L1 - for sending txns on L1
export const walletClientL1 = createWalletClient({
  account,
  chain: sepolia,
  transport: http(),
}).extend(walletActionsL1());

// Public client L2 (Giwa Sepolia)
export const publicClientL2 = createPublicClient({
  chain: giwaSepolia,
  transport: http(),
}).extend(publicActionsL2());

// Wallet client L2 - for sending txns on L2
export const walletClientL2 = createWalletClient({
  account,
  chain: giwaSepolia,
  transport: http(),
}).extend(walletActionsL2());
EOF
    echo -e "${GREEN}✓ Created config.ts${NC}"

    # Create deposit_eth.ts
    cat > deposit_eth.ts << 'EOF'
// deposit_eth.ts
import { publicClientL1, publicClientL2, account, walletClientL1 } from "./config";
import { formatEther, parseEther } from "viem";
import { getL2TransactionHashes } from "viem/op-stack";

async function main() {
  // 1) Check L1 balance
  const l1Balance = await publicClientL1.getBalance({ address: account.address });
  console.log(`L1 Balance: ${formatEther(l1Balance)} ETH`);

  // 2) Build deposit transaction (mint amount on L2)
  // Replace "0.001" with the amount you want to deposit
  const depositArgs = await publicClientL2.buildDepositTransaction({
    mint: parseEther("0.001"),
    to: account.address,
  });

  // 3) Send deposit on L1 (this sends ETH to OptimismPortal)
  const depositHash = await walletClientL1.depositTransaction(depositArgs);
  console.log(`Deposit transaction hash on L1: ${depositHash}`);

  // 4) Wait for L1 tx to confirm
  const depositReceipt = await publicClientL1.waitForTransactionReceipt({ hash: depositHash });
  console.log("L1 transaction confirmed:", depositReceipt.transactionHash);

  // 5) Compute corresponding L2 tx hash
  const [l2Hash] = getL2TransactionHashes(depositReceipt);
  console.log(`Corresponding L2 transaction hash (precomputed): ${l2Hash}`);

  // 6) Wait for L2 transaction receipt
  const l2Receipt = await publicClientL2.waitForTransactionReceipt({ hash: l2Hash });
  console.log("L2 transaction confirmed:", l2Receipt.transactionHash);

  console.log("Deposit completed successfully!");
}

main().catch((err) => {
  console.error("Error:", err);
  process.exit(1);
});
EOF
    echo -e "${GREEN}✓ Created deposit_eth.ts${NC}"

    # Create withdraw_eth.ts
    cat > withdraw_eth.ts << 'EOF'
// withdraw_eth.ts
import { publicClientL1, publicClientL2, account, walletClientL1, walletClientL2 } from "./config";
import { formatEther, parseEther } from "viem";

async function main() {
  // 1) Check L2 balance
  const l2Balance = await publicClientL2.getBalance({ address: account.address });
  console.log(`L2 Balance: ${formatEther(l2Balance)} ETH`);

  // 2) Build withdrawal initiation args (value is the ETH to withdraw)
  const withdrawalArgs = await publicClientL1.buildInitiateWithdrawal({
    to: account.address,
    value: parseEther("0.00005"),
  });

  // 3) Initiate withdrawal on L2 (sends to L2ToL1MessagePasser)
  const withdrawalHash = await walletClientL2.initiateWithdrawal(withdrawalArgs);
  console.log(`Withdrawal transaction hash on L2: ${withdrawalHash}`);

  // 4) Wait for L2 confirmation
  const withdrawalReceipt = await publicClientL2.waitForTransactionReceipt({ hash: withdrawalHash });
  console.log("L2 transaction confirmed:", withdrawalReceipt.transactionHash);

  // 5) Wait until withdrawal can be proven on L1 (can take up to ~2 hours)
  const { output, withdrawal } = await publicClientL1.waitToProve({
    receipt: withdrawalReceipt,
    targetChain: walletClientL2.chain,
  });

  // 6) Build prove args and submit prove tx on L1
  const proveArgs = await publicClientL2.buildProveWithdrawal({
    output,
    withdrawal,
  });

  const proveHash = await walletClientL1.proveWithdrawal(proveArgs);
  console.log(`Prove transaction hash on L1: ${proveHash}`);

  const proveReceipt = await publicClientL1.waitForTransactionReceipt({ hash: proveHash });
  console.log("Prove transaction confirmed:", proveReceipt.transactionHash);

  // 7) Wait for finalization (challenge period ~7 days on optimistic systems)
  await publicClientL1.waitToFinalize({
    targetChain: walletClientL2.chain,
    withdrawalHash: withdrawal.withdrawalHash,
  });

  // 8) Finalize withdrawal on L1
  const finalizeHash = await walletClientL1.finalizeWithdrawal({
    targetChain: walletClientL2.chain,
    withdrawal,
  });
  console.log(`Finalize transaction hash on L1: ${finalizeHash}`);

  const finalizeReceipt = await publicClientL1.waitForTransactionReceipt({ hash: finalizeHash });
  console.log("Finalize transaction confirmed:", finalizeReceipt.transactionHash);

  console.log("Withdrawal completed successfully!");
}

main().catch((err) => {
  console.error("Error:", err);
  process.exit(1);
});
EOF
    echo -e "${GREEN}✓ Created withdraw_eth.ts${NC}"

    # Create package.json
    cat > package.json << 'EOF'
{
  "name": "giwa-bridging-eth",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "deposit": "node --import=tsx deposit_eth.ts",
    "withdraw": "node --import=tsx withdraw_eth.ts"
  },
  "devDependencies": {
    "tsx": "^3.12.7",
    "@types/node": "^20.0.0"
  },
  "dependencies": {
    "viem": "^1.0.0",
    "dotenv": "^16.4.5"
  }
}
EOF
    echo -e "${GREEN}✓ Created package.json${NC}"

    # Create .env file
    cat > .env << 'EOF'
TEST_PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE
EOF
    echo -e "${GREEN}✓ Created .env file${NC}"
    echo -e "${YELLOW}Please update your TEST_PRIVATE_KEY in the .env file${NC}"
}

# Function to check if .env has private key
check_env() {
    if grep -q "0xYOUR_PRIVATE_KEY_HERE" .env; then
        echo -e "${RED}Please update your TEST_PRIVATE_KEY in .env file${NC}"
        read -p "Press any key to open the .env file..."
        nano .env
    fi
    
    if ! grep -q "TEST_PRIVATE_KEY=0x" .env; then
        echo -e "${RED}Invalid TEST_PRIVATE_KEY in .env file${NC}"
        exit 1
    fi
}

# Function to install dependencies
install_dependencies() {
    echo -e "${YELLOW}Installing dependencies...${NC}"
    pnpm install
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install dependencies.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Dependencies installed successfully.${NC}"
}

# Function to bridge from Sepolia to GIWA
bridge_to_giwa() {
    echo -e "${YELLOW}Bridging from Sepolia to GIWA...${NC}"
    echo -e "${BLUE}This might take a few minutes...${NC}"
    node --import=tsx deposit_eth.ts
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Bridging to GIWA completed successfully!${NC}"
    else
        echo -e "${RED}Bridging to GIWA failed.${NC}"
    fi
    read -p "Press any key to continue..."
}

# Function to bridge from GIWA to Sepolia
bridge_to_sepolia() {
    echo -e "${YELLOW}Bridging from GIWA to Sepolia...${NC}"
    echo -e "${BLUE}This might take a few minutes...${NC}"
    node --import=tsx withdraw_eth.ts
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Bridging to Sepolia completed successfully!${NC}"
    else
        echo -e "${RED}Bridging to Sepolia failed.${NC}"
    fi
    read -p "Press any key to continue..."
}

# Function to check balances
check_balances() {
    echo -e "${YELLOW}Checking balances...${NC}"
    # This would need to be implemented with custom scripts
    echo -e "${BLUE}Balance checking feature coming soon!${NC}"
    read -p "Press any key to continue..."
}

# Main menu
main_menu() {
    while true; do
        show_header
        echo -e "${GREEN}Main Menu:${NC}"
        echo "1. Bridge Sepolia to GIWA"
        echo "2. Bridge GIWA to Sepolia"
        echo "3. Check Balances"
        echo "4. Install Dependencies"
        echo "5. Exit"
        echo
        read -p "Please choose an option [1-5]: " choice
        
        case $choice in
            1)
                bridge_to_giwa
                ;;
            2)
                bridge_to_sepolia
                ;;
            3)
                check_balances
                ;;
            4)
                install_dependencies
                ;;
            5)
                echo -e "${GREEN}Thank you for using GIWA Bridge!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                sleep 1
                ;;
        esac
    done
}

# Initial setup function
setup() {
    show_header
    echo -e "${YELLOW}Welcome to GIWA Bridge Setup${NC}"
    echo
    check_writable_dir
    check_node
    check_pnpm
    create_files
    check_env
    install_dependencies
    echo -e "${GREEN}Setup completed successfully!${NC}"
    read -p "Press any key to continue to the main menu..."
}

# Start the application
show_header
echo -e "${YELLOW}GIWA Bridge Script${NC}"
echo
echo "This script will help you:"
echo "1. Install Node.js (if not installed)"
echo "2. Add your private key"
echo "3. Bridge from Sepolia to GIWA"
echo "4. Bridge from GIWA to Sepolia"
echo
read -p "Do you want to run the setup now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    setup
    main_menu
else
    echo -e "${YELLOW}You can run the setup later by running this script again.${NC}"
    exit 0
fi
