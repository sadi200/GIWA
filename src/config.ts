// src/config.ts
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
