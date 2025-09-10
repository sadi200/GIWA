// src/deposit_eth.ts
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
