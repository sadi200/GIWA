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

# Function to check if .env exists and has private key
check_env() {
    if [ ! -f .env ]; then
        echo -e "${YELLOW}.env file not found. Creating one...${NC}"
        touch .env
        echo "TEST_PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE" >> .env
        echo -e "${YELLOW}Please edit .env file and add your private key.${NC}"
        read -p "Press any key to continue after adding your private key..."
    fi
    
    if grep -q "0xYOUR_PRIVATE_KEY_HERE" .env; then
        echo -e "${RED}Please update your TEST_PRIVATE_KEY in .env file${NC}"
        read -p "Press any key to open the .env file..."
        nano .env
    fi
}

# Function to install dependencies
install_dependencies() {
    echo -e "${YELLOW}Installing dependencies...${NC}"
    pnpm add dotenv
    pnpm add viem@latest
    pnpm install
    pnpm add -D tsx @types/node
    echo -e "${GREEN}Dependencies installed successfully.${NC}"
}

# Function to bridge from Sepolia to GIWA
bridge_to_giwa() {
    echo -e "${YELLOW}Bridging from Sepolia to GIWA...${NC}"
    echo -e "${BLUE}This might take a few minutes...${NC}"
    node --import=tsx src/deposit_eth.ts
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
    node --import=tsx src/withdraw_eth.ts
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
    check_node
    check_pnpm
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
