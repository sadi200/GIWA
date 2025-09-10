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

# Default Sepolia RPC (can be overridden by user)
SEPOLIA_RPC="${SEPOLIA_RPC:-https://sepolia.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161}"

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
    echo -e "${YELLOW}Current Sepolia RPC: $SEPOLIA_RPC${NC}"
    echo "=================================================="
    echo
}

# Function to configure Sepolia RPC manually
configure_sepolia_rpc() {
    show_header
    echo -e "${YELLOW}Configure Sepolia RPC Endpoint${NC}"
    echo
    echo "Current RPC: $SEPOLIA_RPC"
    echo
    echo "You can use:"
    echo "1. Infura (default)"
    echo "2. Alchemy"
    echo "3. QuickNode"
    echo "4. Custom RPC"
    echo "5. Keep current"
    echo
    read -p "Choose option [1-5]: " rpc_choice
    
    case $rpc_choice in
        1)
            read -p "Enter Infura Project ID: " infura_id
            SEPOLIA_RPC="https://sepolia.infura.io/v3/$infura_id"
            ;;
        2)
            read -p "Enter Alchemy API Key: " alchemy_key
            SEPOLIA_RPC="https://eth-sepolia.g.alchemy.com/v2/$alchemy_key"
            ;;
        3)
            read -p "Enter QuickNode URL: " quicknode_url
            SEPOLIA_RPC="$quicknode_url"
            ;;
        4)
            read -p "Enter Custom RPC URL: " custom_rpc
            SEPOLIA_RPC="$custom_rpc"
            ;;
        5)
            echo -e "${GREEN}Keeping current RPC: $SEPOLIA_RPC${NC}"
            ;;
        *)
            echo -e "${RED}Invalid option. Keeping current RPC.${NC}"
            ;;
    esac
    
    # Save to .rpc_config file
    echo "SEPOLIA_RPC=$SEPOLIA_RPC" > .rpc_config
    echo -e "${GREEN}RPC configured successfully!${NC}"
    echo -e "${YELLOW}New RPC: $SEPOLIA_RPC${NC}"
    sleep 2
}

# Function to load RPC config if exists
load_rpc_config() {
    if [ -f .rpc_config ]; then
        source .rpc_config
    fi
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
    
    # Create config.ts with configurable RPC
    cat > config.ts << EOF
// config.ts
import { defineChain, createPublicClient, createWalletClient, http } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { sepolia } from "viem/chains";
import dotenv from "dotenv";

dotenv.config();

if (!process.env.TEST_PRIVATE_KEY) {
  throw new Error("Set TEST_PRIVATE_KEY in .env");
}

export const PRIVATE_KEY = process.env.TEST_PRIVATE_KEY as \`0x\${string}\`;
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

// Public client L1 (Ethereum Sepolia) with configurable RPC
export const publicClientL1 = createPublicClient({
  chain: sepolia,
  transport: http("$SEPOLIA_RPC"),
});

// Wallet client L1 - for sending txns on L1
export const walletClientL1 = createWalletClient({
  account,
  chain: sepolia,
  transport: http("$SEPOLIA_RPC"),
});

// Public client L2 (Giwa Sepolia)
export const publicClientL2 = createPublicClient({
  chain: giwaSepolia,
  transport: http(),
});

// Wallet client L2 - for sending txns on L2
export const walletClientL2 = createWalletClient({
  account,
  chain: giwaSepolia,
  transport: http(),
});
EOF
    echo -e "${GREEN}✓ Created config.ts${NC}"

    # Create deposit_eth.ts with simplified implementation
    cat > deposit_eth.ts << 'EOF'
// deposit_eth.ts
import { publicClientL1, publicClientL2, account, walletClientL1 } from "./config";
import { formatEther, parseEther } from "viem";

async function main() {
  try {
    // 1) Check L1 balance
    const l1Balance = await publicClientL1.getBalance({ address: account.address });
    console.log(`L1 Balance: ${formatEther(l1Balance)} ETH`);

    // 2) Prepare deposit transaction
    const value = parseEther("0.001");
    
    // 3) Send deposit transaction to portal contract
    const depositHash = await walletClientL1.sendTransaction({
      to: "0x956962C34687A954e611A83619ABaA37Ce6bC78A", // Portal address
      value: value,
      data: "0x", // Empty data for simple ETH transfer
    });
    
    console.log(`Deposit transaction hash on L1: ${depositHash}`);

    // 4) Wait for L1 tx to confirm
    const depositReceipt = await publicClientL1.waitForTransactionReceipt({ hash: depositHash });
    console.log("L1 transaction confirmed:", depositReceipt.transactionHash);

    console.log("Deposit initiated successfully!");
    console.log("Please wait for the transaction to be processed on L2 (may take a few minutes)");
    
  } catch (err) {
    console.error("Error:", err);
    process.exit(1);
  }
}

main();
EOF
    echo -e "${GREEN}✓ Created deposit_eth.ts${NC}"

    # Create withdraw_eth.ts with simplified implementation
    cat > withdraw_eth.ts << 'EOF'
// withdraw_eth.ts
import { publicClientL1, publicClientL2, account, walletClientL1, walletClientL2 } from "./config";
import { formatEther, parseEther } from "viem";

async function main() {
  try {
    // 1) Check L2 balance
    const l2Balance = await publicClientL2.getBalance({ address: account.address });
    console.log(`L2 Balance: ${formatEther(l2Balance)} ETH`);

    // 2) Prepare withdrawal transaction
    const value = parseEther("0.00005");
    
    // 3) Send withdrawal transaction on L2
    const withdrawalHash = await walletClientL2.sendTransaction({
      to: account.address, // Self-transfer to initiate withdrawal
      value: value,
      data: "0x", // Empty data for simple ETH transfer
    });
    
    console.log(`Withdrawal transaction hash on L2: ${withdrawalHash}`);

    // 4) Wait for L2 confirmation
    const withdrawalReceipt = await publicClientL2.waitForTransactionReceipt({ hash: withdrawalHash });
    console.log("L2 transaction confirmed:", withdrawalReceipt.transactionHash);

    console.log("Withdrawal initiated successfully!");
    console.log("Please wait for the challenge period (may take several hours to days)");
    
  } catch (err) {
    console.error("Error:", err);
    process.exit(1);
  }
}

main();
EOF
    echo -e "${GREEN}✓ Created withdraw_eth.ts${NC}"

    # Create package.json with specific viem version
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
    "viem": "^1.12.2",
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
    echo -e "${BLUE}Using RPC: $SEPOLIA_RPC${NC}"
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
    
    # Create a simple balance checker script
    cat > check_balances.ts << 'EOF'
// check_balances.ts
import { publicClientL1, publicClientL2, account } from "./config";
import { formatEther } from "viem";

async function main() {
  try {
    console.log("Checking balances...");
    
    // Check L1 balance
    const l1Balance = await publicClientL1.getBalance({ address: account.address });
    console.log(`L1 (Sepolia) Balance: ${formatEther(l1Balance)} ETH`);
    
    // Check L2 balance
    const l2Balance = await publicClientL2.getBalance({ address: account.address });
    console.log(`L2 (Giwa) Balance: ${formatEther(l2Balance)} ETH`);
    
  } catch (err) {
    console.error("Error checking balances:", err);
  }
}

main();
EOF
    
    node --import=tsx check_balances.ts
    read -p "Press any key to continue..."
}

# Function to test RPC connection
test_rpc_connection() {
    echo -e "${YELLOW}Testing Sepolia RPC connection...${NC}"
    echo -e "${BLUE}RPC URL: $SEPOLIA_RPC${NC}"
    
    # Create a simple test script
    cat > test_rpc.ts << EOF
// test_rpc.ts
import { createPublicClient, http } from "viem";
import { sepolia } from "viem/chains";

async function main() {
  try {
    const client = createPublicClient({
      chain: sepolia,
      transport: http("$SEPOLIA_RPC"),
    });
    
    const blockNumber = await client.getBlockNumber();
    console.log("Connected to Sepolia network");
    console.log("Current block number:", blockNumber.toString());
    
    return true;
  } catch (err) {
    console.error("Failed to connect to RPC:", err.message);
    return false;
  }
}

main();
EOF
    
    if node --import=tsx test_rpc.ts; then
        echo -e "${GREEN}RPC connection successful!${NC}"
    else
        echo -e "${RED}RPC connection failed!${NC}"
        echo -e "${YELLOW}You may want to configure a different RPC endpoint.${NC}"
    fi
    
    rm -f test_rpc.ts
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
        echo "4. Configure Sepolia RPC"
        echo "5. Test RPC Connection"
        echo "6. Install Dependencies"
        echo "7. Exit"
        echo
        read -p "Please choose an option [1-7]: " choice
        
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
                configure_sepolia_rpc
                # Recreate config file with new RPC
                create_files
                ;;
            5)
                test_rpc_connection
                ;;
            6)
                install_dependencies
                ;;
            7)
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
    load_rpc_config
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
load_rpc_config
show_header
echo -e "${YELLOW}GIWA Bridge Script${NC}"
echo
echo "This script will help you:"
echo "1. Install Node.js (if not installed)"
echo "2. Add your private key"
echo "3. Configure Sepolia RPC"
echo "4. Bridge from Sepolia to GIWA"
echo "5. Bridge from GIWA to Sepolia"
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
