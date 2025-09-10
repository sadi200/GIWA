// src/withdraw_eth.ts
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
